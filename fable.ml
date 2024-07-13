let write_file name content =
  Out_channel.with_open_text name (fun oc -> Printf.fprintf oc "%s\n" content)

let standalone = ref false
let testing = ref false
let yes_to_all = ref false
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
    ("-y", Arg.Set yes_to_all, "Say yes to all interactive commands");
  ]

let run_command_for_user ~cwd cmd =
  Format.printf "run: %s? [y/n]@?" cmd;
  if !yes_to_all || "y" = String.trim (input_line stdin) then begin
    if !yes_to_all then Format.printf "ys@.";
    let r = Sys.command (Format.asprintf "cd %s && %s" cwd cmd) in
    if r <> 0 then Format.printf "%s failed!@." cmd
  end

let write_standalone dir frontmatter json =
  match Sys.file_exists dir with
  | true -> Format.printf "%s already exists@." dir
  | false ->
    Sys.mkdir dir 0o777;
    let s = Format.asprintf in
    write_file (s "%s/index.html" dir)
      (let extra =
         List.assoc_opt "extra" frontmatter |> Option.value ~default:""
       in
       Embedded.index extra);
    write_file (s "%s/default.css" dir) Embedded.default_css;
    write_file (s "%s/interpret.js" dir) Embedded.interpret;
    write_file (s "%s/runtime.js" dir) Embedded.runtime;
    (* testing *)
    if !testing then begin
      write_file (s "%s/test.js" dir) Embedded.test;
      write_file (s "%s/dune-project" dir) "(lang dune 3.15)";
      write_file (s "%s/dune" dir) "(cram (deps (glob_files *)))";
      run_command_for_user ~cwd:dir "chmod +x test.js";
      run_command_for_user ~cwd:dir "npm install selenium-webdriver"
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
