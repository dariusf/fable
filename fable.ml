let write_file name content =
  Out_channel.with_open_text name (fun oc -> Printf.fprintf oc "%s\n" content)

let standalone = ref false
let input_files = ref []
let output_file = ref None

let arg_specs =
  [
    ("-s", Arg.Set standalone, "Create a standlone directory");
    ( "-o",
      Arg.String (fun s -> output_file := Some s),
      "If standalone, the directory name, otherwise the name of the \
       instruction data in JSON" );
  ]

let write_standalone dir frontmatter json =
  match Sys.file_exists dir with
  | true -> Format.printf "%s already exists@." dir
  | false ->
    Sys.mkdir dir 0o777;
    let s = Format.asprintf in
    let extra =
      List.assoc_opt "extra" frontmatter |> Option.value ~default:""
    in
    write_file (s "%s/index.html" dir) (Embedded.index extra);
    write_file (s "%s/default.css" dir) Embedded.default_css;
    write_file (s "%s/interpret.js" dir) Embedded.interpret;
    write_file (s "%s/runtime.js" dir) Embedded.runtime;
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
