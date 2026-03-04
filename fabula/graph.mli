open Ast

type renderer

val graphviz_renderer : renderer
val mermaid_renderer : renderer
val program_graph : renderer -> scene list -> string
