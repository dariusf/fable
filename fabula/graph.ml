open Ast
open Common

type renderer =
  (string -> string -> static:bool -> both:bool -> string) * (string -> string)

let graphviz_renderer : renderer =
  ( (* ~edge: *) (fun a b ~static ~both ->
      let attrs =
        match (static, both) with
        | true, true -> " [dir=both]"
        | false, true -> " [dir=both, style=dashed]"
        | true, false -> ""
        | false, false -> " [style=dashed]"
      in
      Format.asprintf {|  "%s" -> "%s"%s;|} a b attrs),
    (* ~overall: *) fun s -> Format.asprintf "digraph G {\n%s\n}" s )

let mermaid_renderer : renderer =
  ( (* ~edge: *) (fun a b ~static ~both ->
      let link =
        match (static, both) with
        | true, false -> "-->"
        | true, true -> "<-->"
        | false, false -> "-.->"
        | false, true -> "<-.->"
      in
      Format.asprintf {|  %s %s %s;|} a link b),
    (* ~overall: *) fun s ->
      {|%%{ init: { 'flowchart': {'defaultRenderer': 'elk' } } }%%
flowchart TD|}
      ^ "\n" ^ s )

(* TODO as we only track edges, if two nodes are merged and are not pointed to by anything else, the resulting node disappears. to fix this we need to track nodes *)
let _merge_chains edges =
  let rec loop edges =
    let out_degree = Hashtbl.create 16 in
    let in_degree = Hashtbl.create 16 in
    List.iter
      (fun (u, v, _) ->
        Hashtbl.replace out_degree u
          (1 + Option.value (Hashtbl.find_opt out_degree u) ~default:0);
        Hashtbl.replace in_degree v
          (1 + Option.value (Hashtbl.find_opt in_degree v) ~default:0))
      edges;
    let can_merge =
      List.find_opt
        (fun (u, v, _) ->
          u <> v
          && Option.value (Hashtbl.find_opt out_degree u) ~default:0 = 1
          && Option.value (Hashtbl.find_opt in_degree v) ~default:0 = 1
          && not (List.exists (fun (x, y, _) -> x = v && y = u) edges))
        edges
    in
    match can_merge with
    | None -> (* base case *) edges
    | Some (u, v, _) ->
      let merged_node = u ^ "\\n" ^ v in
      let new_edges =
        List.filter_map
          (fun (src, dst, static) ->
            if src = u && dst = v then None
            else
              let src = if src = u || src = v then merged_node else src in
              let dst = if dst = u || dst = v then merged_node else dst in
              Some (src, dst, static))
          edges
      in
      loop (List.sort_uniq compare new_edges)
  in
  loop edges

let collapse_bidirectional edges =
  let rec aux acc = function
    | [] -> Acc.to_list acc
    | (u, v, static) :: rest ->
      let is_reverse (x, y, _) = x = v && y = u in
      (match List.find_opt is_reverse rest with
      | Some (_, _, static2) ->
        let rest = List.filter (fun e -> not (is_reverse e)) rest in
        aux (Acc.add (min u v, max u v, static && static2, true) acc) rest
      | None -> aux (Acc.add (u, v, static, false) acc) rest)
  in
  aux Acc.empty edges

let program_graph
    (* (~edge:render_edge, ~overall) *)
      ((render_edge, overall) : renderer) prog =
  let regexes prog =
    List.map
      (fun c ->
        (* relies on the content of code blocks being JS... but we're a practical system *)
        let r =
          {|\(.\|
\)*\(jump(['"]\|tunnel(['"]\|->\|jump \|>->\|tunnel \)|}
          ^ c.name ^ {|\b|}
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
  let raw_edges =
    prog
    |> List.concat_map (fun sc ->
        let name = sc.name in
        let scenes_to =
          List.concat_map outgoing_scenes sc.cmds |> List.sort_uniq compare
        in
        List.map (fun (s, static) -> (name, s, static)) scenes_to)
  in

  let preprocessed_edges =
    raw_edges
    (* |> merge_chains *)
    |> collapse_bidirectional
  in

  let edges_str =
    preprocessed_edges
    |> List.map (fun (u, v, static, both) -> render_edge u v ~static ~both)
    |> String.concat "\n"
  in
  overall edges_str
(* Format.asprintf "digraph G {\n%s\n}" edges *)
