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
               Fabula.md_to_instrs (Jv.to_string s)
               |> ocaml_to_jv Fabula.program_to_yojson) );
         ( "mayHaveText",
           Jv.callback ~arity:1 (fun s ->
               Fabula.may_have_text (jv_to_ocaml Fabula.cmd_of_yojson s)
               |> Jv.of_bool) );
         ( "useRandomSeed",
           Jv.callback ~arity:1 (fun s -> Random.init (Jv.to_int s)) );
         ( "random",
           Jv.callback ~arity:1 (fun () -> Random.float 1. |> Jv.of_float) );
         ( "randomIncl",
           (* randomIncl(1, 3) = 1 + Random.int ((3+1)-1) *)
           Jv.callback ~arity:2 (fun l h ->
               let l = Jv.to_int l in
               let h = Jv.to_int h in
               let r = l + Random.int (h + 1 - l) in
               Jv.of_int r) );
         ( "randomExcl",
           Jv.callback ~arity:2 (fun l h ->
               let l = Jv.to_int l in
               let h = Jv.to_int h in
               let r = l + Random.int (h - l) in
               Jv.of_int r) );
         ("coin", Jv.callback ~arity:0 (fun () -> Random.bool () |> Jv.of_bool));
         (* ( "instantiate",
            Jv.callback ~arity:2 (fun s bs ->
                Fabula.instantiate (obj_to_assoc bs)
                  (jv_to_ocaml Fabula.cmd_of_yojson s)
                |> ocaml_to_jv Fabula.cmd_to_yojson) ); *)
         (* ( "containsControlChange",
            Jv.callback ~arity:1 (fun ss ->
                Fabula.contains_control_change
                  (jv_to_ocaml Fabula.cmds_of_yojson ss)
                |> Jv.of_bool) ); *)
         ( "recursivelyAddChoices",
           Jv.callback ~arity:2 (fun f ss ->
               Fabula.recursively_add_choices
                 (fun s ->
                   Jv.apply f [| Jv.of_string s |]
                   |> jv_to_ocaml Fabula.cmds_of_yojson)
                 (jv_to_ocaml Fabula.more_of_yojson ss)
               |> ocaml_to_jv Fabula.choices_to_yojson) );
       |])
