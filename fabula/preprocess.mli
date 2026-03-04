(** Allows us to treat Markdown inside HTML tags atomically, as a single
    Inline.Raw_html node *)
val run : Cmarkit.Doc.t -> Cmarkit.Doc.t
