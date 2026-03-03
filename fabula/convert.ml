open Common
open Ast
open Cmarkit

let inline_cmd_folder section =
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
        match () with
        | _ when String.starts_with ~prefix:"$" c ->
          Interpolate (strip_prefix 1 c)
        | _ when String.starts_with ~prefix:"~" c -> Meta (strip_prefix 1 c)
        | _ when String.starts_with ~prefix:"->$" c ->
          JumpDynamic (strip_prefix 3 c)
        | _ when String.starts_with ~prefix:"jump " c ->
          let dest = strip_prefix 5 c in
          (match dest with "" -> Jump section | _ -> Jump dest)
        | _ when String.starts_with ~prefix:"->" c ->
          let dest = strip_prefix 2 c in
          (match dest with "" -> Jump section | _ -> Jump dest)
        | _ when String.starts_with ~prefix:"tunnel " c ->
          Tunnel (strip_prefix 7 c)
        | _ when String.starts_with ~prefix:">->" c -> Tunnel (strip_prefix 3 c)
        | _ -> Run (String.trim c)
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
    | Inline.Raw_html (ls, _) ->
      let l =
        List.map (fun (a, (b, _)) -> a ^ b) ls
        |> String.concat "\n" |> String.trim
      in
      (* Format.printf "(raw html %s)@." l; *)
      if String.starts_with ~prefix:"<!--" l then Folder.default
      else Folder.ret (Acc.add (Verbatim l) acc)
    | Inline.Strong_emphasis (_, _) -> failwith "unimplemented Strong_emphasis"
    | _ -> Folder.default
  in
  Folder.make ~inline ()

let check_no_sticky_and_otherwise choices =
  let has_sticky =
    List.exists
      (fun c -> match c.kind with Sticky -> true | Consumable _ -> false)
      choices
  in
  let has_otherwise = List.exists (fun c -> c.otherwise) choices in
  if has_sticky && has_otherwise then
    fail "sticky is incompatible with otherwise"

let check_only_one_otherwise choices =
  let count =
    List.fold_right (fun c t -> if c.otherwise then 1 + t else t) choices 0
  in
  if count > 1 then fail "more than one otherwise"

let block_cmd_folder =
  let block : (Block.t, (string * cmd Acc.t) Acc.t) Folder.folder =
   fun self acc b ->
    match b with
    | Block.Paragraph (p, _m) ->
      let section, _ = Acc.last acc |> Option.get in
      let a =
        Folder.fold_inline
          (inline_cmd_folder section)
          Acc.empty (Block.Paragraph.inline p)
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
          | [_; "meta"] | [_; "~"] -> MetaBlock (String.trim content)
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
        Folder.fold_inline inline_text_folder Acc.empty (Block.Heading.inline h)
        |> Acc.to_list |> String.concat "" |> String.trim
      in
      Folder.ret (Acc.add (name, Acc.empty) acc)
    | Block.Html_block (b, _) ->
      let l = List.map Block_line.to_string b |> String.concat "\n" in
      let elt = VerbatimBlock (String.trim l) in
      if String.starts_with ~prefix:"<!--" l then Folder.default
      else
        Folder.ret
          (Acc.change_last (fun (name, cmds) -> (name, Acc.add elt cmds)) acc)
    | Block.Link_reference_definition (_, _) ->
      failwith "unimplemented Link_reference_definition"
    | Block.List (l, _) ->
      let section, _ = Acc.last acc |> Option.get in
      let list_item_to_choice i =
        let bs =
          Folder.fold_block self
            (Acc.add (section, Acc.empty) Acc.empty)
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
          let sticky = ref false in
          let otherwise = ref false in
          let preconditions = ref Acc.empty in
          let initial = ref Acc.empty in
          let code = ref None in
          let rest = ref Acc.empty in
          para
          |> List.iter (fun e ->
              match (e, !code) with
              (* special things encoded as Runs *)
              | Run "sticky", _ -> sticky := true
              | Run "otherwise", _ -> otherwise := true
              | Run s, _ when String.starts_with ~prefix:"guard " s ->
                preconditions := Acc.add (strip_prefix 6 s) !preconditions
              | Run s, _ when String.starts_with ~prefix:"?" s ->
                preconditions := Acc.add (strip_prefix 1 s) !preconditions
              (* things to stop at *)
              | (Break | Run _ | Jump _ | JumpDynamic _ | Tunnel _), None ->
                code := Some e
              (* the rest *)
              | _, Some _ -> rest := Acc.add e !rest
              | _, None -> initial := Acc.add e !initial);
          `Choice
            {
              otherwise = !otherwise;
              guard = Acc.to_list !preconditions;
              initial = Acc.to_list !initial;
              code = Option.to_list !code;
              rest =
                (let r = Acc.to_list !rest in
                 match r with [] -> after_first | _ -> Para r :: after_first);
              kind =
                (if !sticky then Sticky else Consumable (fresh ~prefix:"c" ()));
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
        (Acc.change_last (fun (name, cmds) -> (name, Acc.add choice cmds)) acc)
    | Block.Thematic_break (_, _) -> Folder.default
    | _ -> Folder.default (* let the folder thread the fold *)
  in
  Folder.make ~block ()

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

let expand_more p =
  let visitor =
    object (_)
      inherit [_] Ast.map_scene
      inherit! [_] Ast.map_cmd
      inherit! [_] Ast.map_program

      method! visit_Choices _env more ch =
        let ch1 =
          recursively_add_choices
            (fun name ->
              (try List.find (fun s -> s.Ast.name = name) p
               with Not_found ->
                 fail "nonexistent section %s used in more" name)
                .cmds)
            more
        in
        Choices ([], ch @ ch1)
    end
  in
  visitor#visit_program () p

let validate p =
  let visitor =
    object (_)
      inherit [_] Ast.map_scene
      inherit! [_] Ast.map_cmd
      inherit! [_] Ast.map_program

      method! visit_Choices _env more ch =
        check_only_one_otherwise ch;
        check_no_sticky_and_otherwise ch;
        Choices (more, ch)
    end
  in
  visitor#visit_program () p

let to_program doc =
  let doc = Preprocess.run doc in
  let acc = Acc.add ("prelude", Acc.empty) Acc.empty in
  let prog = Folder.fold_doc block_cmd_folder acc doc in
  let scenes =
    Acc.to_list prog
    |> List.filter_map (fun (name, cmds) ->
        let cmds = Acc.to_list cmds in
        match cmds with [] -> None | _ -> Some { name; cmds })
  in
  scenes |> expand_more |> validate
