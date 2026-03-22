open Ast

val recursively_add_choices : (string -> cmd list) -> more -> choice_item list

(*** Converts Markdown into a Fable program *)
val to_program : Cmarkit.Doc.t -> program
