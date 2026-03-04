(** A library for working with Fable. Used by CLI tool, editor, and runtime. *)
open Ast

exception InputError of string

type frontmatter = (string * string) list

(** * Parsing *)

(** May fail with an [InputError] *)
val parse_md_file : string -> frontmatter * Ast.program

(** May fail with an [InputError] *)
val parse_str : string -> Ast.program

val print_story_js : ?out:out_channel -> program -> unit

(** * Processing *)

(** Overapproximate check for whether a command produces text *)
val may_have_text : cmd -> bool

(** Pulls in choices recursively from a "more" scene *)
val recursively_add_choices :
  (string -> Ast.cmd list) -> Ast.more -> Ast.choice list

(* * Program graphs *)
type renderer

val graphviz_renderer : renderer
val mermaid_renderer : renderer
val program_graph : renderer -> scene list -> string

(* * JSON *)
val program_to_yojson : program -> Yojson.Safe.t
val cmd_of_yojson : Yojson.Safe.t -> cmd Ppx_deriving_yojson_runtime.error_or
val choices_to_yojson : choices -> Yojson.Safe.t
val cmds_of_yojson : Yojson.Safe.t -> cmds Ppx_deriving_yojson_runtime.error_or
val more_of_yojson : Yojson.Safe.t -> more Ppx_deriving_yojson_runtime.error_or
