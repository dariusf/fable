let write_file name content =
  Out_channel.with_open_text name (fun oc -> Printf.fprintf oc "%s\n" content)

let standalone = ref false
let testing = ref false
let input_files = ref []
let output_file = ref None
let show_stats = ref false

let arg_specs =
  [
    ("--stats", Arg.Set show_stats, "Show stats");
    ("-s", Arg.Set standalone, "Create a standlone directory");
    ("-t", Arg.Set testing, "Generates a testing setup");
    ( "-o",
      Arg.String (fun s -> output_file := Some s),
      "If standalone, the directory name, otherwise the name of the \
       instruction data in JSON" );
  ]

let substitute_vars vars content =
  List.fold_left
    (fun acc (k, v) ->
      let r = Str.regexp_string ("{{" ^ k ^ "}}") in
      Str.global_replace r v acc)
    content vars

let write_standalone dir frontmatter json =
  let get_fm fm name default =
    List.assoc_opt name fm |> Option.value ~default
  in
  match Sys.file_exists dir with
  | true ->
    Format.printf "%s already exists@." dir;
    exit 1
  | false ->
    Sys.mkdir dir 0o777;
    let s = Format.asprintf in
    write_file (s "%s/index.html" dir)
      begin
        substitute_vars
          [
            ("title", get_fm frontmatter "title" "Fable");
            ("extra", get_fm frontmatter "extra" "");
          ]
          Embedded.index
      end;
    write_file (s "%s/default.css" dir)
      begin
        substitute_vars
          [
            ("light_bg", get_fm frontmatter "light_bg" "#f7f7f7");
            ("light_bg_lighter", get_fm frontmatter "light_bg_lighter" "#fafafa");
            ("light_fg", get_fm frontmatter "light_fg" "#000000");
            ("dark_bg", get_fm frontmatter "dark_bg" "#202124");
            ("dark_bg_lighter", get_fm frontmatter "dark_bg_lighter" "#4e5159");
            ("dark_fg", get_fm frontmatter "dark_fg" "#e8eaed");
          ]
          Embedded.default_css
      end;
    write_file (s "%s/interpret.js" dir) Embedded.interpret;
    write_file (s "%s/runtime.js" dir) Embedded.runtime;
    write_file (s "%s/graph.dot" dir)
      (Fabula.Graph.(program_graph graphviz_renderer) json);
    write_file (s "%s/graph.mmd" dir)
      (Fabula.Graph.(program_graph mermaid_renderer) json);
    (* testing *)
    if !testing then begin
      write_file (s "%s/test.js" dir) Embedded.test;
      write_file (s "%s/dune-project" dir) "(lang dune 3.15)";
      write_file (s "%s/dune" dir) "(cram (deps (glob_files *)))"
    end;
    (* done *)
    if !show_stats then Format.printf "%s@." (Fabula.collate_stats json);
    Out_channel.with_open_text (s "%s/story.js" dir) (fun out ->
        Fabula.print_story_js ~out json)

let () =
  Arg.parse arg_specs
    (fun filename -> input_files := filename :: !input_files)
    "fable [-s] <file1> [<file2>] ... -o <output>";
  match !input_files with
  | [f] ->
    (match Fabula.parse_md_file f with
    | exception Fabula.InputError s ->
      Format.eprintf "error: %s@." s;
      exit 1
    | frontmatter, json ->
      (match !standalone with
      | true ->
        (match !output_file with
        | None -> Format.printf "expected an output directory name@."
        | Some dir -> write_standalone dir frontmatter json)
      | false ->
        (match !output_file with
        | None -> Fabula.print_story_js json
        | Some o ->
          Out_channel.with_open_text o (fun out ->
              Fabula.print_story_js ~out json))))
  | _ -> Format.printf "expected one input file@."

(* let () =
   let d = Cmarkit.Doc.of_string {|a <span>b</span> c|} in
   let d = Fabula.Preprocess.run d in
   Format.printf "%s@." (Cmarkit_html.of_doc ~safe:true d);
   Format.printf "%s@." (Cmarkit_commonmark.of_doc d);
   Format.printf "%a@." Fabula.pp_program (Fabula.Convert.to_program d) *)
