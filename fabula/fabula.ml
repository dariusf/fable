open Common
include Ast

exception InputError = Common.InputError

let rec may_have_text s =
  match s with
  | Para p | Emph p -> List.exists may_have_text p
  | Verbatim t | VerbatimBlock t | Text t -> String.length (String.trim t) > 0
  | Break | LinkCode _ | LinkJump _ | Interpolate _ -> true
  | Choices (ms, cs) -> (not (List.is_empty ms)) || not (List.is_empty cs)
  | Meta _ | MetaBlock _ ->
    (* overapproximation *)
    true
  | Run _ | Tunnel _ | Jump _ | JumpDynamic _ -> false

(* let rec instantiate bs s =
   match s with
   | Para p -> Para (List.map (instantiate bs) p)
   | Verbatim _ | Break | Text _ | LinkCode _ | LinkJump _ | Run _ | Jump _ -> s
   | Meta _ ->
     (* for now *)
     s
   | Interpolate i when List.mem_assoc i bs -> Interpolate (List.assoc i bs)
   | Interpolate _ -> s
   | JumpDynamic i when List.mem_assoc i bs -> JumpDynamic (List.assoc i bs)
   | JumpDynamic _ -> s
   | Choices (m, cs) ->
     Choices
       ( m,
         List.map
           (fun c ->
             {
               c with
               initial = List.map (instantiate bs) c.initial;
               code = List.map (instantiate bs) c.code;
               rest = List.map (instantiate bs) c.rest;
             })
           cs ) *)

let recursively_add_choices = Convert.recursively_add_choices

(* let contains_control_change s =
   let rec aux s =
     match s with
     | Para ps -> List.exists aux ps
     | Tunnel _ | JumpDynamic _ | Jump _ -> true
     | Break | Verbatim _ | VerbatimBlock _ | Text _
     | LinkCode (_, _)
     | LinkJump (_, _)
     | Run _ | Interpolate _ ->
       false
     | Meta _ | MetaBlock _
     | Choices (_, _) ->
       (* overapproximation *)
       true
   in
   List.exists aux s *)

let graphviz_renderer =
  ( (* ~edge: *) (fun a b static ->
      Format.asprintf {|  "%s" -> "%s"%s;|} a b
        (if static then "" else " [style=dashed]")),
    (* ~overall: *) fun s -> Format.asprintf "digraph G {\n%s\n}" s )

let mermaid_renderer =
  ( (* ~edge: *) (fun a b static ->
      Format.asprintf {|  %s -%s-> %s;|} a (if static then "" else ".") b),
    (* ~overall: *) fun s ->
      {|%%{ init: { 'flowchart': {'defaultRenderer': 'elk' } } }%%
flowchart TD|}
      ^ "\n" ^ s )

let program_graph
    (* (~edge:render_edge, ~overall) *)
      (render_edge, overall) prog =
  let regexes prog =
    List.map
      (fun c ->
        (* relies on the content of code blocks being JS... but we're a practical system *)
        let r =
          {|\(.\|
\)*\(jump(['"]\|tunnel(['"]\|->\|jump \|>->\|tunnel \)|}
          ^ c.name
        in
        (c.name, Str.regexp r))
      prog
  in
  let found regexes str =
    List.filter_map
      (fun (n, r) -> if Str.string_match r str 0 then Some n else None)
      regexes
  in
  let regexes = regexes prog in
  let rec outgoing_scenes c =
    match c with
    | LinkCode (_, _)
    | Interpolate _ | Run _ | VerbatimBlock _ | Verbatim _ | Text _ | Break ->
      []
    | Para p | Emph p -> List.concat_map outgoing_scenes p
    | JumpDynamic _ ->
      (* cannot tell *)
      []
    | Jump s | Tunnel s | LinkJump (_, s) -> [(s, true)]
    | Meta b | MetaBlock b ->
      (* cannot tell in general *)
      found regexes b |> List.map (fun i -> (i, false))
    | Choices (_, cs) ->
      List.concat_map
        (fun c ->
          List.concat
            (List.map
               (List.concat_map outgoing_scenes)
               [c.initial; c.code; c.rest]))
        cs
  in
  let edges =
    prog
    |> List.concat_map (fun sc ->
        let name = sc.name in
        let scenes_to =
          List.concat_map outgoing_scenes sc.cmds |> List.sort_uniq compare
        in
        scenes_to
        |> List.map (fun (s, static) ->
            render_edge name s static
            (* Format.asprintf {|  "%s" -> "%s"%s;|} name s *)
            (* (if static then "" else " [style=dashed]") *)))
    |> String.concat "\n"
  in
  overall edges
(* Format.asprintf "digraph G {\n%s\n}" edges *)

let print_json ?out program =
  let compact = true in
  let program = program_to_yojson program in
  if compact then (
    let out = Option.value out ~default:stdout in
    Printf.fprintf out "var story = ";
    Yojson.Safe.to_channel ~std:true out program;
    Printf.fprintf out ";\n%!")
  else
    match out with
    | None -> Format.printf "%a@." (Yojson.Safe.pretty_print ~std:true) program
    | Some out -> Yojson.Safe.to_channel out ~std:true program

let match_all groups regex str =
  let rec loop p =
    match Str.search_forward regex str p with
    | _ ->
      let r = List.map (fun g -> Str.matched_group g str) groups in
      r :: loop (Str.match_end () + 0)
    | exception Not_found -> []
  in
  loop 0

let extract_frontmatter =
  let fm_regex = Str.regexp "\\([ -~\n]+\\)---\n\\([ -~\n]*\\)\n*" in
  let simple_kvp = Str.regexp "\\([a-z]+\\): \\([ -~]+\\)" in
  let multiline_kvp = Str.regexp "\\([a-z]+\\): |\n\\(\\( +[ -~]+\n\\)+\\)" in
  fun str ->
    let exception Fail in
    try
      let@ _ = if_exn_then Fail in
      let front, rest =
        let[@warning "-8"] [[front; rest]] = match_all [1; 2] fm_regex str in
        (front, rest)
      in
      let multi =
        let multi = match_all [1; 2] multiline_kvp front in
        multi
        |> List.map (fun[@warning "-8"] [k; v] ->
            let v1 =
              String.split_on_char '\n' v
              |> List.map String.trim |> String.concat "\n"
            in
            (k, v1))
      in
      let simple =
        let simple = match_all [1; 2] simple_kvp front in
        (* this matches multi too so remove those *)
        simple
        |> List.filter_map (fun[@warning "-8"] [k; v] ->
            if List.exists (fun (mk, _) -> mk = k) multi then None
            else Some (k, v))
      in
      (simple @ multi, rest)
    with Fail -> ([], str)

let md_file_to_json file =
  let str = Common.read_file file in
  let front, str = extract_frontmatter str in
  let doc =
    (* ~resolver:Convert.resolver  *)
    Cmarkit.Doc.of_string str
  in
  (* Format.printf "html: %s@." (Cmarkit_html.of_doc ~safe:true doc); *)
  (front, doc |> Convert.to_program)

let md_to_instrs str =
  (* ~resolver:Convert.resolver  *)
  let doc = Cmarkit.Doc.of_string str in
  doc |> Convert.to_program
