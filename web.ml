let () =
  Jv.set Jv.global "scripture_parse"
    (Jv.callback ~arity:1 (fun s ->
         let r = Scripture.md_to_instrs (Jv.to_string s) |> Jstr.of_string in
         Brr.Json.decode r |> Result.get_ok))
