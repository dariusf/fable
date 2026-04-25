open Ast

val recursively_add_choices : (string -> cmd list) -> more -> choice_item list

(*** Converts Markdown into scenes *)
val to_scenes : Cmarkit.Doc.t -> scenes
