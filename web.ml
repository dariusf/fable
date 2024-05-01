(* let obj_to_assoc obj =
   let ks =
     Jv.call (Jv.get Jv.global "Object") "keys" [| obj |]
     |> Jv.to_array Jv.to_string
   in
   Array.map (fun k -> (k, Jv.get obj k |> Jv.to_string)) ks |> Array.to_list *)

let jv_to_ocaml f v =
  Brr.Json.encode v |> Jstr.to_string |> Yojson.Safe.from_string |> f
  |> Result.get_ok

let ocaml_to_jv f v =
  f v
  |> Yojson.Safe.to_string ~std:true
  |> Jstr.of_string |> Brr.Json.decode |> Result.get_ok

let () =
  Jv.set Jv.global "Fable"
    (Jv.obj
       [|
         ( "parse",
           Jv.callback ~arity:1 (fun s ->
               Fable.md_to_instrs (Jv.to_string s)
               |> ocaml_to_jv Fable.program_to_yojson) );
         ( "mayHaveText",
           Jv.callback ~arity:1 (fun s ->
               Fable.may_have_text (jv_to_ocaml Fable.cmd_of_yojson s)
               |> Jv.of_bool) );
         (* ( "instantiate",
            Jv.callback ~arity:2 (fun s bs ->
                Fable.instantiate (obj_to_assoc bs)
                  (jv_to_ocaml Fable.cmd_of_yojson s)
                |> ocaml_to_jv Fable.cmd_to_yojson) ); *)
         ( "containsControlChange",
           Jv.callback ~arity:1 (fun ss ->
               Fable.contains_control_change
                 (jv_to_ocaml Fable.cmds_of_yojson ss)
               |> Jv.of_bool) );
         ( "recursivelyAddChoices",
           Jv.callback ~arity:2 (fun f ss ->
               Fable.recursively_add_choices
                 (fun s ->
                   Jv.apply f [| Jv.of_string s |]
                   |> jv_to_ocaml Fable.cmds_of_yojson)
                 (jv_to_ocaml Fable.more_of_yojson ss)
               |> ocaml_to_jv Fable.choices_to_yojson) );
       |])
