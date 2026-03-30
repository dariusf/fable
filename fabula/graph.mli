open Ast

type renderer

val graphviz_renderer : renderer
val mermaid_renderer : renderer
val program_graph : renderer -> program -> string

(** The bool indicates if the edge is static. *)
val raw_edges : program -> (string * string * bool) list
