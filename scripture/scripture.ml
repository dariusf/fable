open Common

type choice = {
  guard : string list;
  initial : cmd list;
  code : cmd list;
  rest : cmd list;
  sticky : bool;
}

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
  | Choices of choice list
[@@deriving show { with_path = false }, yojson]

type scene = {
  name : string;
  cmds : cmd list;
}
[@@deriving show { with_path = false }, yojson]

type program = scene list [@@deriving show { with_path = false }, yojson]

let _ = pp_program

module Convert = struct
  open Cmarkit

  let inline_text_folder =
    Folder.make
      ~inline:(fun _f acc i ->
        match i with
        | Inline.Text (s, _) -> Folder.ret (Acc.add s acc)
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
      | Inline.Text (s, _) -> Folder.ret (Acc.add (Text s) acc)
      | Inline.Autolink (_, _) -> failwith "unimplemented Autolink"
      | Inline.Break (_, _) -> Folder.ret (Acc.add Break acc)
      | Inline.Code_span (cs, _) ->
        let c = Inline.Code_span.code cs in
        let r =
          if String.starts_with ~prefix:"$" c then Interpolate (suffix 1 c)
          else if String.starts_with ~prefix:"~" c then Meta (suffix 1 c)
          else if String.starts_with ~prefix:"jump " c then Jump (suffix 5 c)
            (* else if String.starts_with ~prefix:"guard " c then *)
            (* Guard (String.sub c 6 (String.length c - 6)) *)
            (* else if String.starts_with ~prefix:"sticky" c then Sticky *)
          else Run c
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
          |> Acc.to_list |> String.concat " "
        in
        let r =
          match Inline.Link.reference l with
          | `Inline (d, _) ->
            (match Link_definition.dest d with
            | None -> failwith "no destination"
            | Some (t1, _) when String.starts_with ~prefix:"#" t1 ->
              let r = String.sub t1 1 (String.length t1 - 1) in
              (* for links like [text](#id) *)
              LinkJump (t, r)
            | Some (t1, _) when String.starts_with ~prefix:"!" t1 ->
              let r = String.sub t1 1 (String.length t1 - 1) in
              LinkCode (t, r)
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
        (* let acc = *)
        (* match Block.Code_block.info_string cb with
           | None -> acc
           | Some (info, _) ->
             (match Block.Code_block.language_of_info_string info with
             | None -> acc
             | Some (lang, _) -> SSet.add lang acc) *)
        (* SSet.add_seq *)
        let content =
          List.map Block_line.to_string (Block.Code_block.code cb)
          |> String.concat "\n" (* |> List.to_seq *)
        in
        (* Acc.add (Run content) acc *)
        let thing =
          match Block.Code_block.info_string cb with
          | None -> Run content
          | Some (s, _) ->
            let segs = String.split_on_char ' ' s in
            (match segs with
            | [_; "meta"] | [_; "~"] -> Meta content
            | _ -> Run content)
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
          |> Acc.to_list |> String.concat ""
        in
        Folder.ret (Acc.add (name, Acc.empty) acc)
      | Block.Html_block (b, _) ->
        let l = List.map Block_line.to_string b |> String.concat "\n" in
        if String.starts_with ~prefix:"<!--" l then Folder.default
        else
          Folder.ret
            (Acc.change_last
               (fun (name, cmds) -> (name, Acc.add (Verbatim l) cmds))
               acc)
      | Block.Link_reference_definition (_, _) ->
        failwith "unimplemented Link_reference_definition"
      | Block.List (l, _) ->
        let choices =
          l |> Block.List'.items
          |> List.map (fun (i, _) ->
                 let bs =
                   Folder.fold_block self
                     (Acc.add ("", Acc.empty) Acc.empty)
                     (Block.List_item.block i)
                   |> Acc.to_list
                 in
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
                 (* only look for special syntax in the first paragraph *)
                 let _, gs, st, i, c, r =
                   para
                   |> List.fold_left
                        (fun (b, gs, st, i, c, r) e ->
                          match (e, b) with
                          | Run "sticky", _ -> (b, gs, true, i, Some e, r)
                          | Run s, _ when String.starts_with ~prefix:"guard " s
                            ->
                            (b, Acc.add (suffix 6 s) gs, st, i, Some e, r)
                          | Run _, false -> (true, gs, st, i, Some e, r)
                          | Jump _, false -> (true, gs, st, i, Some e, r)
                          | _, true -> (true, gs, st, i, c, Acc.add e r)
                          | _, false -> (false, gs, st, Acc.add e i, c, r))
                        (false, Acc.empty, false, Acc.empty, None, Acc.empty)
                 in
                 {
                   guard = Acc.to_list gs;
                   initial = Acc.to_list i;
                   code = Option.to_list c;
                   rest =
                     (let r = Acc.to_list r in
                      match r with
                      | [] -> after_first
                      | _ -> Para r :: after_first);
                   sticky = st;
                 })
        in
        Folder.ret
          (Acc.change_last
             (fun (name, cmds) -> (name, Acc.add (Choices choices) cmds))
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

let print_json program =
  let compact = true in
  let program = program_to_yojson program in
  if compact then (
    print_string "const data = ";
    Yojson.Safe.to_channel ~std:true stdout program;
    print_endline ";")
  else Format.printf "%a@." (Yojson.Safe.pretty_print ~std:true) program

let md_file_to_json file =
  let doc =
    (* ~resolver:Convert.resolver  *)
    Cmarkit.Doc.of_string (Common.read_file file)
  in
  (* Format.printf "html: %s@." (Cmarkit_html.of_doc ~safe:true doc); *)
  doc |> Convert.to_program |> print_json

let md_to_instrs str =
  (* ~resolver:Convert.resolver  *)
  let doc = Cmarkit.Doc.of_string str in
  doc |> Convert.to_program |> program_to_yojson
  |> Yojson.Safe.to_string ~std:true
