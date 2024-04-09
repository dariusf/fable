open Common

type choice = {
  initial : cmd list;
  code : cmd list;
  rest : cmd;
}

and cmd =
  | Verbatim of string
  | Para of cmd list
  | Text of string
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
      | Inline.Break (_, _) -> failwith "unimplemented Break"
      | Inline.Code_span (cs, _) ->
        let c = Inline.Code_span.code cs in
        let r =
          if String.starts_with ~prefix:"$" c then
            Interpolate (String.sub c 1 (String.length c - 1))
          else if String.starts_with ~prefix:"~" c then
            Meta (String.sub c 1 (String.length c - 1))
          else if String.starts_with ~prefix:"jump " c then
            Jump (String.sub c 5 (String.length c - 5))
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
        Folder.ret (Acc.change_last (fun (_, cmds) -> (name, cmds)) acc)
      | Block.Html_block (b, _) ->
        let l = List.map Block_line.to_string b |> String.concat "\n" in
        Folder.ret
          (Acc.change_last
             (fun (name, cmds) -> (name, Acc.add (Verbatim l) cmds))
             acc)
      | Block.Link_reference_definition (_, _) ->
        failwith "unimplemented Link_reference_definition"
      | Block.List (l, _) ->
        let cs =
          List.map
            (fun (i, _) ->
              let bs =
                Folder.fold_block self
                  (Acc.add ("", Acc.empty) Acc.empty)
                  (Block.List_item.block i)
              in
              (* show_block (Block.List_item.block i); *)
              let _, bs = List.hd (Acc.to_list bs) in
              (* it's a para *)
              let bs =
                match Acc.to_list bs with
                | [Para b] -> b
                | _ -> failwith "not a para?"
              in
              let _, i, c, r =
                List.fold_left
                  (fun (b, i, c, r) e ->
                    match (e, b) with
                    | Run _, false -> (true, i, Some e, r)
                    | Jump _, false -> (true, i, Some e, r)
                    | _, true -> (true, i, c, Acc.add e r)
                    | _, false -> (false, Acc.add e i, c, r))
                  (false, Acc.empty, None, Acc.empty)
                  bs
              in
              {
                initial = Acc.to_list i;
                code = Option.to_list c;
                rest = Para (Acc.to_list r);
              })
            (Block.List'.items l)
        in
        Folder.ret
          (Acc.change_last
             (fun (name, cmds) -> (name, Acc.add (Choices cs) cmds))
             acc)
      | Block.Thematic_break (_, _) ->
        Folder.ret (Acc.add ("none", Acc.empty) acc)
      | _ -> Folder.default (* let the folder thread the fold *)
    in
    Folder.make ~block ()

  let to_program doc =
    (* ~inline  *)
    let acc = Acc.add ("default", Acc.empty) Acc.empty in
    let prog = Folder.fold_doc block_cmd_folder acc doc in
    (* SSet.elements langs *)
    Acc.to_list prog
    |> List.map (fun (name, cmds) -> { name; cmds = Acc.to_list cmds })

  (* let wikilink = Cmarkit.Meta.key () (* A meta key to recognize them *)

     let make_wikilink label =
       (* Just a placeholder label definition *)
       let meta = Cmarkit.Meta.tag wikilink (Cmarkit.Label.meta label) in
       Cmarkit.Label.with_meta meta label

     (* copied from docs. keeps unresolved links instead of turning them into text *)
     let resolver = function
       | `Def _ as ctx -> Cmarkit.Label.default_resolver ctx
       | `Ref (_, _, (Some _ as def)) -> def (* As per doc definition *)
       | `Ref (_, ref, None) -> Some (make_wikilink ref) *)
end

(* let rec interp program cmds =
     match cmds with
     | [] -> ()
     | Run c :: cs ->
       eval c |> ignore;
       interp program cs
     | Print c :: cs ->
       append c |> ignore;
       interp program cs
     | Interpolate c :: cs ->
       append (eval c |> Jv.to_string);
       interp program cs
     | Choices chs :: cs -> failwith "choice" *)

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
