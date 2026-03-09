open Common
open Cmarkit

(** Allows us to treat Markdown inside HTML tags atomically, as a single
    Inline.Raw_html node *)
module CollapseTags = struct
  (** the partial contents of a paragraph, as a list of potential raw html
      blocks (lists), and a stack of currently open tags *)
  type t = Inline.t Acc.t Acc.t * string list

  (* true for opening, false for closing *)
  let get_tag =
    let regexp = Str.regexp {|<\(/?\)\([a-z-]+\).*>|} in
    fun s ->
      if Str.string_match regexp s 0 then
        Some (String.length (Str.matched_group 1 s) = 0, Str.matched_group 2 s)
      else None

  let inline : t Folder.t =
    let inline _self (acc, curr_tag) inl =
      match inl with
      | Inline.Raw_html (tag, _m) ->
        let tag = List.map snd tag |> List.map fst |> String.concat "" in
        (* Format.printf "tag |%s|@." tag; *)
        (match (get_tag tag, curr_tag) with
        | None, [] ->
          (* Format.printf "no element, no block open@."; *)
          (* not an element, no block is open *)
          Folder.ret (Acc.add (Acc.add inl Acc.empty) acc, [])
        | Some (true, t), [] ->
          (* Format.printf "start new block@."; *)
          (* start a new block *)
          Folder.ret (Acc.add (Acc.add inl Acc.empty) acc, [t])
        | Some (_, t), t1 :: _ when t <> t1 ->
          (* nest *)
          (* Format.printf "nest@."; *)
          Folder.ret (Acc.change_last (Acc.add inl) acc, curr_tag)
        | Some (true, _), _ :: _ ->
          (* nest also *)
          (* Format.printf "nest also@."; *)
          Folder.ret (Acc.change_last (Acc.add inl) acc, curr_tag)
        | None, _ :: _ ->
          (* not an element, add to current block *)
          (* Format.printf "not an element, add to current block@."; *)
          Folder.ret (Acc.change_last (Acc.add inl) acc, curr_tag)
        | Some (false, t), t1 :: rest when t = t1 ->
          (* close current block *)
          (* Format.printf "close current block@."; *)
          Folder.ret (Acc.change_last (Acc.add inl) acc, rest)
        | Some (false, _), _ -> failwith "unmatched closing tag")
      | Inline.Text _ ->
        (match curr_tag with
        | [] ->
          (* Format.printf "text on its own@."; *)
          Folder.ret (Acc.add (Acc.add inl Acc.empty) acc, curr_tag)
        | _ :: _ ->
          (* Format.printf "text existing@."; *)
          Folder.ret (Acc.change_last (Acc.add inl) acc, curr_tag))
      (* | Inline.Autolink (_, _) ->
           Format.printf "autolink@.";
           Folder.ret (Acc.add (Acc.add inl Acc.empty) acc, curr_tag)
         | Inline.Break (_, _) ->
           Format.printf "break@.";
           Folder.ret (Acc.add (Acc.add inl Acc.empty) acc, curr_tag)
         | Inline.Code_span (_, _) ->
           Format.printf "code span@.";
           Folder.ret (Acc.add (Acc.add inl Acc.empty) acc, curr_tag)
         | Inline.Emphasis (_, _) ->
           Format.printf "emphasis@.";
           Folder.ret (Acc.add (Acc.add inl Acc.empty) acc, curr_tag)
         | Inline.Image (_, _) ->
           Format.printf "imag@.";
           Folder.ret (Acc.add (Acc.add inl Acc.empty) acc, curr_tag) *)
      | Inline.Inlines (_is, _) ->
        (* Format.printf "inlines@."; *)
        (* Folder.ret (Acc.add (Acc.add inl Acc.empty) acc, None) *)
        Folder.default
      (* | Inline.Link (_, _) ->
           Format.printf "link@.";
           Folder.ret (Acc.add (Acc.add inl Acc.empty) acc, curr_tag)
         | Inline.Strong_emphasis (_, _) ->
           Format.printf "strong@.";
           Folder.ret (Acc.add (Acc.add inl Acc.empty) acc, curr_tag) *)
      | _ ->
        (match curr_tag with
        | [] ->
          (* Format.printf "other inline on its own@."; *)
          Folder.ret (Acc.add (Acc.add inl Acc.empty) acc, curr_tag)
        | _ :: _ ->
          (* Format.printf "other inline existing@."; *)
          Folder.ret (Acc.change_last (Acc.add inl) acc, curr_tag))
      (* Folder.default *)
    in

    Folder.make ~inline ()

  let block _ = function
    | Block.Paragraph (p, _m) ->
      let p, stk =
        Folder.fold_inline inline (Acc.empty, []) (Block.Paragraph.inline p)
      in
      (match stk with [] -> () | a :: _ -> fail "unclosed tag %s" a);
      let p =
        Inline.Inlines
          ( Acc.to_list p
            |> List.map (fun a ->
                let l = Acc.to_list a in
                if List.length l > 1 then
                  let ls =
                    Folder.fold_inline inline_text_folder Acc.empty
                      (Inline.Inlines (l, Meta.none))
                    |> Acc.to_list |> String.concat "" |> String.trim
                  in
                  [Inline.Raw_html ([("", (ls, Meta.none))], Meta.none)]
                else l)
            |> List.concat,
            Meta.none )
      in
      Mapper.ret (Block.Paragraph (Block.Paragraph.make p, _m))
    | _ -> Mapper.default
end

module SmartyPants = struct
  let smartypants =
    let em_dash = Str.regexp_string "---" in
    let en_dash = Str.regexp_string "--" in
    let ellipsis = Str.regexp_string "..." in
    let apostrophe = Str.regexp "'\\([st]\\)" in
    let opening_single = Str.regexp "\\(^\\|[ \t\n(]\\)'" in
    let closing_single = Str.regexp_string "'" in
    let opening_double = Str.regexp "\\(^\\|[ \t\n(]\\)\"" in
    let closing_double = Str.regexp_string "\"" in
    fun s ->
      s (* the order matters *)
      |> Str.global_replace em_dash "—"
      |> Str.global_replace en_dash "–"
      |> Str.global_replace ellipsis "…"
      |> Str.global_replace apostrophe "’\\1"
      |> Str.global_replace opening_single "\\1‘"
      |> Str.global_replace closing_single "’"
      |> Str.global_replace opening_double "\\1“"
      |> Str.global_replace closing_double "”"

  let inline_mapper _ = function
    | Inline.Text (s, meta) -> Mapper.ret (Inline.Text (smartypants s, meta))
    | _ -> Mapper.default
end

module DoubleSemicolon = struct
  let split_inlines (inls : Inline.t list) : Inline.t list list =
    let rec loop current_para paras = function
      | [] -> List.rev (List.rev current_para :: paras)
      | inl :: rest ->
        (match inl with
        | Inline.Text (s, meta) ->
          let parts = Str.split_delim (Str.regexp_string ";;") s in
          (match parts with
          | [] -> loop current_para paras rest
          | [p] -> loop (Inline.Text (p, meta) :: current_para) paras rest
          | first :: others ->
            let paras =
              List.rev (Inline.Text (first, meta) :: current_para) :: paras
            in
            let rec fold_others paras = function
              | [] -> failwith "impossible"
              | [last] -> loop [Inline.Text (last, meta)] paras rest
              | t :: ts ->
                fold_others (List.rev [Inline.Text (t, meta)] :: paras) ts
            in
            fold_others paras others)
        | Inline.Inlines (ls, _meta) -> loop current_para paras (ls @ rest)
        | _ -> loop (inl :: current_para) paras rest)
    in
    loop [] [] inls
    |> List.map (fun inls ->
        List.filter
          (function Inline.Text (s, _) when s = "" -> false | _ -> true)
          inls)
    |> List.filter (function [] -> false | _ -> true)

  let _block _ = function
    | Block.Paragraph (p, m) ->
      let inls = [Block.Paragraph.inline p] in
      let splitted = split_inlines inls in
      (match splitted with
      | [] -> Mapper.default
      | [one] ->
        let p = Block.Paragraph.make (Inline.Inlines (one, Meta.none)) in
        Mapper.ret (Block.Paragraph (p, m))
      | many ->
        let paras =
          List.map
            (fun inls ->
              let inline = Inline.Inlines (inls, Meta.none) in
              Block.Paragraph (Block.Paragraph.make inline, Meta.none))
            many
        in
        Mapper.ret (Block.Blocks (paras, Meta.none)))
    | _ -> Mapper.default
end

module SemicolonBreak = struct
  let split_inlines (inls : Inline.t list) : Inline.t list list =
    let rec loop current_para paras = function
      | [] -> List.rev (List.rev current_para :: paras)
      | inl :: rest ->
        (match inl with
        | Inline.Code_span (cs, _) when Inline.Code_span.code cs = ";" ->
          loop [] (List.rev current_para :: paras) rest
        | Inline.Inlines (ls, _meta) -> loop current_para paras (ls @ rest)
        | _ -> loop (inl :: current_para) paras rest)
    in
    loop [] [] inls
    |> List.map (fun inls ->
        List.filter
          (function
            | Inline.Text (s, _) when String.trim s = "" -> false | _ -> true)
          inls)
    |> List.filter (function [] -> false | _ -> true)

  let block _ = function
    | Block.Paragraph (p, m) ->
      let inls = [Block.Paragraph.inline p] in
      let splitted = split_inlines inls in
      (match splitted with
      | [] -> Mapper.default
      | [one] ->
        let p = Block.Paragraph.make (Inline.Inlines (one, Meta.none)) in
        Mapper.ret (Block.Paragraph (p, m))
      | many ->
        let paras =
          List.map
            (fun inls ->
              let inline = Inline.Inlines (inls, Meta.none) in
              Block.Paragraph (Block.Paragraph.make inline, Meta.none))
            many
        in
        Mapper.ret (Block.Blocks (paras, Meta.none)))
    | _ -> Mapper.default
end

let run doc =
  doc
  |> Mapper.map_doc (Mapper.make ~inline:SmartyPants.inline_mapper ())
  |> Mapper.map_doc (Mapper.make ~block:SemicolonBreak.block ())
  (* |> Mapper.map_doc (Mapper.make ~block:DoubleSemicolon.block ()) *)
  |> Mapper.map_doc (Mapper.make ~block:CollapseTags.block ())
