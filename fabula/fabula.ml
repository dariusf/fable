open Common
module Ast = Ast
module Graph = Graph
include Ast

exception InputError = Common.InputError

let rec may_have_text s =
  match s with
  | Para p | Emph p -> List.exists may_have_text p
  | Verbatim t | VerbatimBlock t | Text t -> String.length (String.trim t) > 0
  | Break | LinkCode _ | LinkJump _ | Interpolate _ -> true
  | Choice c -> (not (List.is_empty c.more)) || not (List.is_empty c.items)
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
   | Choice (m, cs) ->
     Choice
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

let recursively_add_choices = Compile.recursively_add_choices

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
     | Choice (_, _) ->
       (* overapproximation *)
       true
   in
   List.exists aux s *)

let print_story_js ?out program =
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

type frontmatter = (string * string) list

let extract_frontmatter : string -> frontmatter * string =
  let fm_regex =
    Str.regexp "[ \n\t]*---\n[ \n\t]*\\([ -~\n]+\\)---\n\\([ -~\n]*\\)\n*"
  in
  let simple_kvp = Str.regexp "\\([a-z_]+\\): \\([ -~]+\\)" in
  let multiline_kvp = Str.regexp "\\([a-z_]+\\): |\n\\(\\( +[ -~]+\n\\)+\\)" in
  fun str ->
    let exception Fail in
    try
      let@ _ = if_any_exn_then Fail in
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

let parse_md_file file =
  let str = Common.read_file file in
  let front, str = extract_frontmatter str in
  let doc =
    (* ~resolver:Compile.resolver  *)
    Cmarkit.Doc.of_string str
  in
  (* Format.printf "html: %s@." (Cmarkit_html.of_doc ~safe:true doc); *)
  (front, doc |> Compile.to_program)

let parse_str str =
  (* ~resolver:Compile.resolver  *)
  let doc = Cmarkit.Doc.of_string str in
  doc |> Compile.to_program

let count_words (p : program) =
  let count = ref 0 in
  let add s =
    let words = String.split_on_char ' ' s in
    List.iter (fun w -> if String.trim w <> "" then incr count) words
  in
  let rec walk_cmd (c : cmd) =
    match c with
    | Text s -> add s
    | Para cmds | Emph cmds -> List.iter walk_cmd cmds
    | Choice { items; _ } ->
      List.iter
        (fun (ch : choice_item) ->
          List.iter walk_cmd ch.initial;
          List.iter walk_cmd ch.rest)
        items
    | _ -> ()
  in
  List.iter (fun (s : scene) -> List.iter walk_cmd s.cmds) p;
  !count
