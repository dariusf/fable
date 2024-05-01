open Common

type choice = {
  guard : string list;
  initial : cmd list;
  code : cmd list;
  rest : cmd list;
  sticky : bool;
}

and more = (string * string) list

and cmd =
  | Verbatim of string
  | Para of cmd list
  | Text of string
  | Break
  | LinkCode of string * string
  | LinkJump of string * string
  | Run of string
  | Interpolate of string
  | Meta of string
  | Jump of string
  | Tunnel of string
  | JumpDynamic of string
  | Choices of more * choice list
[@@deriving show { with_path = false }, yojson]

type scene = {
  name : string;
  cmds : cmd list;
}
[@@deriving show { with_path = false }, yojson]

type program = scene list [@@deriving show { with_path = false }, yojson]
type cmds = cmd list [@@deriving show { with_path = false }, yojson]
type choices = choice list [@@deriving yojson]

let _ = pp_program

module Convert = struct
  open Cmarkit

  let inline_text_folder =
    Folder.make
      ~inline:(fun _f acc i ->
        match i with
        | Inline.Text (s, _) when not (is_whitespace s) ->
          Folder.ret (Acc.add (String.trim s) acc)
        | Inline.Text _ -> Folder.default
        | Inline.Autolink (_, _) -> failwith "unimplemented Autolink"
        | Inline.Break (_, _) -> failwith "unimplemented Break"
        | Inline.Code_span (_, _) -> failwith "code span"
        | Inline.Emphasis (_, _) -> failwith "unimplemented Emphasis"
        | Inline.Image (_, _) -> failwith "unimplemented Image"
        | Inline.Inlines (_is, _) -> Folder.default
        | Inline.Link (_, _) -> failwith "unimplemented Link"
        | Inline.Raw_html (_, _) -> failwith "unimplemented Raw_html"
        | Inline.Strong_emphasis (_, _) ->
          failwith "unimplemented Strong_emphasis"
        | _ -> Folder.default)
      ()

  let inline_cmd_folder =
    let inline : (Inline.t, cmd Acc.t) Folder.folder =
     fun _f acc i ->
      match i with
      | Inline.Text (s, _) when not (is_whitespace s) ->
        Folder.ret (Acc.add (Text (String.trim s)) acc)
      | Inline.Text _ -> Folder.default
      | Inline.Autolink (_, _) -> failwith "unimplemented Autolink"
      | Inline.Break (_, _) -> Folder.ret (Acc.add Break acc)
      | Inline.Code_span (cs, _) ->
        let c = Inline.Code_span.code cs in
        let r =
          if String.starts_with ~prefix:"$" c then
            Interpolate (strip_prefix 1 c)
          else if String.starts_with ~prefix:"~" c then Meta (strip_prefix 1 c)
          else if String.starts_with ~prefix:"->$" c then
            JumpDynamic (strip_prefix 3 c)
          else if String.starts_with ~prefix:"jump " c then
            Jump (strip_prefix 5 c)
          else if String.starts_with ~prefix:"->" c then Jump (strip_prefix 2 c)
          else if String.starts_with ~prefix:"tunnel " c then
            Tunnel (strip_prefix 7 c)
          else if String.starts_with ~prefix:">->" c then
            Tunnel (strip_prefix 3 c)
          else Run (String.trim c)
        in
        Folder.ret (Acc.add r acc)
      | Inline.Emphasis (_, _) -> failwith "unimplemented Emphasis"
      | Inline.Image (_, _) -> failwith "unimplemented Image"
      | Inline.Inlines (_is, _) ->
        (* Format.printf "INLINES@.";
           List.iter show_inline _is;
           Format.printf "---@."; *)
        Folder.default
        (* Folder.ret
           (List.fold_left
              (fun t c -> Acc.plus (Folder.fold_inline f Acc.empty c) t)
              Acc.empty is) *)
      | Inline.Link (l, _) ->
        let t =
          Folder.fold_inline inline_text_folder Acc.empty (Inline.Link.text l)
          |> Acc.to_list |> String.concat " " |> String.trim
        in
        let r =
          match Inline.Link.reference l with
          | `Inline (d, _) ->
            (match Link_definition.dest d with
            | None -> failwith "no destination"
            | Some (t1, _) when String.starts_with ~prefix:"#" t1 ->
              let r = String.sub t1 1 (String.length t1 - 1) in
              (* for links like [text](#id) *)
              LinkJump (String.trim t, String.trim r)
            | Some (t1, _) when String.starts_with ~prefix:"!" t1 ->
              let r = String.sub t1 1 (String.length t1 - 1) in
              LinkCode (String.trim t, String.trim r)
            | Some _ -> failwith "unknown kind of link")
          | `Ref (_, _l, _) ->
            (* for links like [text][ref] *)
            failwith "reference links not supported"
          (* LinkCode (t, Label.key l) *)
        in
        Folder.ret (Acc.add r acc)
      | Inline.Raw_html (_, _) -> failwith "unimplemented Raw_html"
      | Inline.Strong_emphasis (_, _) ->
        failwith "unimplemented Strong_emphasis"
      | _ -> Folder.default
    in

    Folder.make ~inline ()

  let block_cmd_folder =
    let block : (Block.t, (string * cmd Acc.t) Acc.t) Folder.folder =
     fun self acc b ->
      match b with
      | Block.Paragraph (p, _m) ->
        let a =
          Folder.fold_inline inline_cmd_folder Acc.empty
            (Block.Paragraph.inline p)
        in
        Folder.ret
          (Acc.change_last
             (fun (name, cmds) -> (name, Acc.add (Para (Acc.to_list a)) cmds))
             acc)
      | Block.Code_block (cb, _meta) ->
        (* match Block.Code_block.info_string cb with
           | None -> acc
           | Some (info, _) ->
             (match Block.Code_block.language_of_info_string info with
             | None -> acc
             | Some (lang, _) -> SSet.add lang acc) *)
        let content =
          List.map Block_line.to_string (Block.Code_block.code cb)
          |> String.concat "\n" |> String.trim
        in
        (* Acc.add (Run content) acc *)
        let thing =
          match Block.Code_block.info_string cb with
          | None -> Run content
          | Some (s, _) ->
            let segs = String.split_on_char ' ' s in
            (match segs with
            | [_; "meta"] | [_; "~"] -> Meta (String.trim content)
            | _ -> Run (String.trim content))
        in
        Folder.ret
          (Acc.change_last (fun (name, cmds) -> (name, Acc.add thing cmds)) acc)
        (* acc *)
        (* in *)
        (* Folder.ret acc *)
      | Block.Blank_line (_, _) ->
        (* Folder.ret
           (Acc.change_last (fun (name, cmds) -> (name, Acc.add Break cmds)) acc) *)
        Folder.default
      | Block.Block_quote (_, _) -> failwith "unimplemented Block_quote"
      | Block.Blocks (_bs, _) ->
        (* Format.printf "BLOCKS@.";
           List.iter show_block _bs;
           Format.printf "---@."; *)
        Folder.default
        (* Folder.ret
           (List.fold_left
              (fun t c -> Acc.plus (Folder.fold_block f Acc.empty c) t)
              Acc.empty bs) *)
      | Block.Heading (h, _) ->
        let name =
          Folder.fold_inline inline_text_folder Acc.empty
            (Block.Heading.inline h)
          |> Acc.to_list |> String.concat "" |> String.trim
        in
        Folder.ret (Acc.add (name, Acc.empty) acc)
      | Block.Html_block (b, _) ->
        let l = List.map Block_line.to_string b |> String.concat "\n" in
        if String.starts_with ~prefix:"<!--" l then Folder.default
        else
          Folder.ret
            (Acc.change_last
               (fun (name, cmds) ->
                 (name, Acc.add (Verbatim (String.trim l)) cmds))
               acc)
      | Block.Link_reference_definition (_, _) ->
        failwith "unimplemented Link_reference_definition"
      | Block.List (l, _) ->
        let list_item_to_choice i =
          let bs =
            Folder.fold_block self
              (Acc.add ("", Acc.empty) Acc.empty)
              (Block.List_item.block i)
            |> Acc.to_list
          in
          (* show_block (Block.List_item.block i); *)
          (* the first block is expected to be a paragraph *)
          let para, after_first =
            match bs with
            | [(_, bs)] ->
              (match Acc.to_list bs with
              | Para b :: rest -> (b, rest)
              | _ ->
                show_block (Block.List_item.block i);
                failwith "not a para followed by rest")
            | _ -> failwith "not a singleton scene"
          in
          match (para, after_first) with
          | [Run g; Run m], []
            when String.starts_with ~prefix:"?" g
                 && String.starts_with ~prefix:"more " m ->
            `More (strip_prefix 1 g, strip_prefix 5 m)
          | [Run g; Run m], []
            when String.starts_with ~prefix:"guard " g
                 && String.starts_with ~prefix:"more " m ->
            `More (strip_prefix 6 g, strip_prefix 5 m)
          | [Run m], [] when String.starts_with ~prefix:"more " m ->
            (* some js leaked in here, but this is the boolean true value in most languages... *)
            `More ("true", strip_prefix 5 m)
          | _ ->
            (* only look for special syntax in the first paragraph *)
            let _, gs, st, i, c, r =
              para
              |> List.fold_left
                   (fun (b, gs, st, i, c, r) e ->
                     match (e, b) with
                     (* special things encoded as Runs *)
                     | Run "sticky", _ -> (b, gs, true, i, Some e, r)
                     | Run s, _ when String.starts_with ~prefix:"guard " s ->
                       (b, Acc.add (strip_prefix 6 s) gs, st, i, Some e, r)
                     | Run s, _ when String.starts_with ~prefix:"?" s ->
                       (b, Acc.add (strip_prefix 1 s) gs, st, i, Some e, r)
                       (* things to stop at *)
                     | (Run _ | Jump _ | JumpDynamic _ | Tunnel _), false ->
                       (true, gs, st, i, Some e, r)
                     (* the rest *)
                     | _, true -> (true, gs, st, i, c, Acc.add e r)
                     | _, false -> (false, gs, st, Acc.add e i, c, r))
                   (false, Acc.empty, false, Acc.empty, None, Acc.empty)
            in
            `Choice
              {
                guard = Acc.to_list gs;
                initial = Acc.to_list i;
                code = Option.to_list c;
                rest =
                  (let r = Acc.to_list r in
                   match r with [] -> after_first | _ -> Para r :: after_first);
                sticky = st;
              }
        in
        let more, choices =
          List.fold_right
            (fun (i, _) (more, cs) ->
              match list_item_to_choice i with
              | `Choice c -> (more, c :: cs)
              | `More (g, m) -> ((g, m) :: more, cs))
            (Block.List'.items l) ([], [])
        in
        let choice = Choices (more, choices) in
        Folder.ret
          (Acc.change_last
             (fun (name, cmds) -> (name, Acc.add choice cmds))
             acc)
      | Block.Thematic_break (_, _) -> Folder.default
      | _ -> Folder.default (* let the folder thread the fold *)
    in
    Folder.make ~block ()

  let to_program doc =
    let acc = Acc.add ("default", Acc.empty) Acc.empty in
    let prog = Folder.fold_doc block_cmd_folder acc doc in
    Acc.to_list prog
    |> List.filter_map (fun (name, cmds) ->
           let cmds = Acc.to_list cmds in
           match cmds with [] -> None | _ -> Some { name; cmds })
end

let rec may_have_text s =
  match s with
  | Para p -> List.exists may_have_text p
  | Verbatim t | Text t -> String.length (String.trim t) > 0
  | Break | LinkCode _ | LinkJump _ | Interpolate _ -> true
  | Choices (ms, cs) -> (not (List.is_empty ms)) || not (List.is_empty cs)
  | Meta _ ->
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

let rec recursively_add_choices f ss =
  List.concat_map
    (fun (g, s) ->
      match f s with
      | [Choices (m, cs)] ->
        cs @ recursively_add_choices f m
        |> List.map (fun c -> { c with guard = g :: c.guard })
      | _e ->
        (* Format.printf "%a@." pp_cmds e; *)
        failwith (s ^ " is not a scene with a single choice in it"))
    ss

let contains_control_change s =
  let rec aux s =
    match s with
    | Para ps -> List.exists aux ps
    | Tunnel _ | JumpDynamic _ | Jump _ -> true
    | Break | Verbatim _ | Text _
    | LinkCode (_, _)
    | LinkJump (_, _)
    | Run _ | Interpolate _ | Meta _ ->
      false
    | Choices (_, _) ->
      (* overapproximation *)
      true
  in
  List.exists aux s

let print_json ?out program =
  let compact = true in
  let program = program_to_yojson program in
  if compact then (
    let out = Option.value out ~default:stdout in
    Printf.fprintf out "const data = ";
    Yojson.Safe.to_channel ~std:true out program;
    Printf.fprintf out ";\n%!")
  else
    match out with
    | None -> Format.printf "%a@." (Yojson.Safe.pretty_print ~std:true) program
    | Some out -> Yojson.Safe.to_channel out ~std:true program

let md_file_to_json file =
  let doc =
    (* ~resolver:Convert.resolver  *)
    Cmarkit.Doc.of_string (Common.read_file file)
  in
  (* Format.printf "html: %s@." (Cmarkit_html.of_doc ~safe:true doc); *)
  doc |> Convert.to_program

let md_to_instrs str =
  (* ~resolver:Convert.resolver  *)
  let doc = Cmarkit.Doc.of_string str in
  doc |> Convert.to_program
