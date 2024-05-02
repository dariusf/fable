(lang dune 3.7)

(name fable)
(generate_opam_files true)

(source
 (github dariusf/fable))

(authors "Darius Foo")

(maintainers "darius.foo.tw@gmail.com")
(license	MIT)

(package
 (name fable)
 (synopsis "Fable")
 (description "Stories")
 (depends
  (ocaml (>= 5.1.0))
  (dune (>= 3.12.1))
  (js_of_ocaml (>= 5.5.2))
  (brr (>= 0.0.6))
  (cmarkit (>= 0.3.0))
  (ppx_deriving (>= 5.2.1))
  (ppx_deriving_yojson (>= 3.7.0))))
