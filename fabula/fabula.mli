(** A library for working with Fable. Used by CLI tool, editor, and runtime. *)
open Ast

module Ast = Ast

exception InputError of string

type frontmatter = (string * string) list

(** * Parsing *)

(** May fail with an [InputError] *)
val parse_md_file : string -> frontmatter * program

(** May fail with an [InputError] *)
val parse_str : string -> program

val print_story_js : ?out:out_channel -> program -> unit

(** * Processing *)

val collate_stats : program -> string

(** Overapproximate check for whether a command produces text *)
val may_have_text : cmd -> bool

(** Pulls in choices recursively from a "more" scene *)
val recursively_add_choices : (string -> cmd list) -> more -> choice_item list

(* * Program graphs *)
module Graph = Graph

(* * JSON *)
val program_to_yojson : program -> Yojson.Safe.t
val cmd_of_yojson : Yojson.Safe.t -> cmd Ppx_deriving_yojson_runtime.error_or
val choice_items_to_yojson : choice_items -> Yojson.Safe.t
val cmds_of_yojson : Yojson.Safe.t -> cmds Ppx_deriving_yojson_runtime.error_or
val more_of_yojson : Yojson.Safe.t -> more Ppx_deriving_yojson_runtime.error_or
