let write_file name content =
  Out_channel.with_open_text name (fun oc -> Printf.fprintf oc "%s\n" content)

let standalone = ref false
let testing = ref false
let input_files = ref []
let output_file = ref None

let arg_specs =
  [
    ("-s", Arg.Set standalone, "Create a standlone directory");
    ("-t", Arg.Set testing, "Generates a testing setup");
    ( "-o",
      Arg.String (fun s -> output_file := Some s),
      "If standalone, the directory name, otherwise the name of the \
       instruction data in JSON" );
  ]

let get_fm fm name default = List.assoc_opt name fm |> Option.value ~default

let write_standalone dir frontmatter json =
  match Sys.file_exists dir with
  | true ->
    Format.printf "%s already exists@." dir;
    exit 1
  | false ->
    Sys.mkdir dir 0o777;
    let s = Format.asprintf in
    write_file (s "%s/index.html" dir)
      begin
        let title = get_fm frontmatter "title" "Fable" in
        let extra = get_fm frontmatter "extra" "" in
        Embedded.index title extra
      end;
    write_file (s "%s/default.css" dir) Embedded.default_css;
    write_file (s "%s/interpret.js" dir) Embedded.interpret;
    write_file (s "%s/runtime.js" dir) Embedded.runtime;
    write_file (s "%s/graph.dot" dir) (Fabula.program_graph json);
    (* testing *)
    if !testing then begin
      write_file (s "%s/test.js" dir) Embedded.test;
      write_file (s "%s/dune-project" dir) "(lang dune 3.15)";
      write_file (s "%s/dune" dir) "(cram (deps (glob_files *)))"
    end;
    (* done *)
    Out_channel.with_open_text (s "%s/story.js" dir) (fun out ->
        Fabula.print_json ~out json)

let () =
  Arg.parse arg_specs
    (fun filename -> input_files := filename :: !input_files)
    "fable [-s] <file1> [<file2>] ... -o <output>";
  match !input_files with
  | [f] ->
    let frontmatter, json = Fabula.md_file_to_json f in
    (match !standalone with
    | true ->
      (match !output_file with
      | None -> Format.printf "expected an output directory name@."
      | Some dir -> write_standalone dir frontmatter json)
    | false ->
      (match !output_file with
      | None -> Fabula.print_json json
      | Some o ->
        Out_channel.with_open_text o (fun out -> Fabula.print_json ~out json)))
  | _ -> Format.printf "expected one input file@."

(* let () =
   let d = Cmarkit.Doc.of_string {|a <span>b</span> c|} in
   let d = Fabula.Preprocess.run d in
   Format.printf "%s@." (Cmarkit_html.of_doc ~safe:true d);
   Format.printf "%s@." (Cmarkit_commonmark.of_doc d);
   Format.printf "%a@." Fabula.pp_program (Fabula.Convert.to_program d) *)
