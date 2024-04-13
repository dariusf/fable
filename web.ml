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
  Jv.set Jv.global "Scripture"
    (Jv.obj
       [|
         ( "parse",
           Jv.callback ~arity:1 (fun s ->
               Scripture.md_to_instrs (Jv.to_string s)
               |> ocaml_to_jv Scripture.program_to_yojson) );
         ( "mayHaveText",
           Jv.callback ~arity:1 (fun s ->
               Scripture.may_have_text (jv_to_ocaml Scripture.cmd_of_yojson s)
               |> Jv.of_bool) );
         (* ( "instantiate",
            Jv.callback ~arity:2 (fun s bs ->
                Scripture.instantiate (obj_to_assoc bs)
                  (jv_to_ocaml Scripture.cmd_of_yojson s)
                |> ocaml_to_jv Scripture.cmd_to_yojson) ); *)
         ( "containsControlChange",
           Jv.callback ~arity:1 (fun ss ->
               Scripture.contains_control_change
                 (jv_to_ocaml Scripture.cmds_of_yojson ss)
               |> Jv.of_bool) );
         ( "recursivelyAddChoices",
           Jv.callback ~arity:2 (fun f ss ->
               Scripture.recursively_add_choices
                 (fun s ->
                   Jv.apply f [| Jv.of_string s |]
                   |> jv_to_ocaml Scripture.cmds_of_yojson)
                 (jv_to_ocaml Scripture.more_of_yojson ss)
               |> ocaml_to_jv Scripture.choices_to_yojson) );
       |])
