open Common

type choice = {
  initial : cmd list;
  code : string;
  rest : cmd list;
}

and cmd =
  | Para of cmd list
  | Text of string
  | Run of string
  | Interpolate of string
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
    | Inline.Link (_, _) -> failwith "unimplemented Link"
    | Inline.Raw_html (_, _) -> failwith "unimplemented Raw_html"
    | Inline.Strong_emphasis (_, _) -> failwith "unimplemented Strong_emphasis"
    | _ -> Folder.default

  let inline_cmd_folder = Folder.make ~inline ()

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
      Folder.ret
        (Acc.change_last
           (fun (name, cmds) -> (name, Acc.add (Run content) cmds))
           acc)
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
        Folder.fold_inline inline_text_folder Acc.empty (Block.Heading.inline h)
        |> Acc.to_list |> String.concat ""
      in
      Folder.ret (Acc.change_last (fun (_, cmds) -> (name, cmds)) acc)
    | Block.Html_block (_, _) -> failwith "unimplemented Html_block"
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
            let _, i, c, r =
              List.fold_left
                (fun (b, i, c, r) e ->
                  match (e, b) with
                  | Run s, false -> (true, i, s, r)
                  | _, true -> (true, i, c, Acc.add e r)
                  | _, false -> (false, Acc.add e i, c, r))
                (false, Acc.empty, "", Acc.empty)
                (Acc.to_list bs)
            in
            { initial = Acc.to_list i; code = c; rest = Acc.to_list r })
          (Block.List'.items l)
      in
      Folder.ret
        (Acc.change_last
           (fun (name, cmds) -> (name, Acc.add (Choices cs) cmds))
           acc)
    | Block.Thematic_break (_, _) ->
      Folder.ret (Acc.add ("none", Acc.empty) acc)
    | _ -> Folder.default (* let the folder thread the fold *)

  let to_program doc =
    (* ~inline  *)
    let folder = Folder.make ~block () in
    let acc = Acc.add ("default", Acc.empty) Acc.empty in
    let prog = Folder.fold_doc folder acc doc in
    (* SSet.elements langs *)
    Acc.to_list prog
    |> List.map (fun (name, cmds) -> { name; cmds = Acc.to_list cmds })
end

(* let eval s = Jv.call Jv.global "eval" [| Jv.of_string s |]
   let append s = Jv.call Jv.global "append" [| Jv.of_string s |] |> ignore

   let rec interp program cmds =
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

let () =
  let doc = Cmarkit.Doc.of_string (read_file Sys.argv.(1)) in
  (* Format.printf "html: %s@." (Cmarkit_html.of_doc ~safe:true doc); *)
  doc |> Convert.to_program |> print_json
