let to_assoc obj =
  let ks =
    Jv.call (Jv.get Jv.global "Object") "keys" [| obj |]
    |> Jv.to_array Jv.to_string
  in
  Array.map (fun k -> (k, Jv.get obj k |> Jv.to_string)) ks |> Array.to_list

let cmds_to_ocaml v =
  Brr.Json.encode v |> Jstr.to_string |> Yojson.Safe.from_string
  |> Scripture.cmds_of_yojson |> Result.get_ok

let ocaml_to_choices v =
  Scripture.choices_to_yojson v
  |> Yojson.Safe.to_string |> Jstr.of_string |> Brr.Json.decode |> Result.get_ok

let () =
  Jv.set Jv.global "Scripture"
    (Jv.obj
       [|
         ( "parse",
           Jv.callback ~arity:1 (fun s ->
               let r =
                 Scripture.md_to_instrs (Jv.to_string s) |> Jstr.of_string
               in
               Brr.Json.decode r |> Result.get_ok) );
         ( "mayHaveText",
           Jv.callback ~arity:1 (fun s -> Scripture.may_have_text s) );
         ( "instantiate",
           Jv.callback ~arity:2 (fun s bs ->
               Scripture.instantiate (to_assoc bs) s) );
         ( "recursivelyAddChoices",
           Jv.callback ~arity:2 (fun f ss ->
               Brr.Console.log ["asdsadsa"; f; ss];
               Scripture.recursively_add_choices
                 (fun s -> Jv.apply f [| Jv.of_string s |] |> cmds_to_ocaml)
                 (Jv.to_list Jv.to_string ss)
               |> ocaml_to_choices) );
       |])
