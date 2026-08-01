let jv_to_ocaml f v =
  Brr.Json.encode v |> Jstr.to_string |> Yojson.Safe.from_string |> f
  |> Result.get_ok'

let ocaml_to_jv f v =
  f v
  |> Yojson.Safe.to_string ~std:true
  |> Jstr.of_string |> Brr.Json.decode |> Result.get_ok

module M = Fabula.Machine

module FromJv = struct
  let assoc obj =
    let ks =
      Jv.call (Jv.get Jv.global "Object") "keys" [| obj |]
      |> Jv.to_array Jv.to_string
    in
    Array.map (fun k -> (k, Jv.get obj k |> Jv.to_string)) ks |> Array.to_list

  let value (v : Jv.t) : M.value =
    if Jv.is_none v then M.VUndefined
    else
      match Jstr.to_string (Jv.typeof v) with
      | "boolean" -> M.VBool (Jv.to_bool v)
      | "number" -> M.VNumber (Jv.to_float v)
      | "string" -> M.VString (Jv.to_string v)
      | _ ->
        let is_array =
          Jv.call (Jv.get Jv.global "Array") "isArray" [| v |] |> Jv.to_bool
        in
        if is_array then M.VCmds (jv_to_ocaml Fabula.cmds_of_yojson v)
        else
          (* objects etc.: JS string coercion, as `v + ""` today *)
          M.VString
            (Jv.apply (Jv.get Jv.global "String") [| v |] |> Jv.to_string)
end

(* Hand-written event conversion (hot path; no yojson round trip). *)
module ToJv = struct
  let obj ty fields =
    Jv.obj (Array.of_list (("type", Jv.of_string ty) :: fields))

  let rec inline (i : M.Event.inline) : Jv.t =
    match i with
    | Text s -> obj "text" [("text", Jv.of_string s)]
    | Space -> obj "space" []
    | Verbatim s -> obj "verbatim" [("html", Jv.of_string s)]
    | Link { link_id; label } ->
      obj "link" [("linkId", Jv.of_int link_id); ("label", Jv.of_string label)]
    | Emph is -> obj "emph" [("content", Jv.of_list inline is)]

  let event (e : M.Event.t) : Jv.t =
    match e with
    | Para is -> obj "para" [("content", Jv.of_list inline is)]
    | Verbatim_block s -> obj "verbatimBlock" [("html", Jv.of_string s)]
    | Choices { node_id; items } ->
      obj "choices"
        [
          ("nodeId", Jv.of_int node_id);
          ( "items",
            Jv.of_list
              (fun (id, content) ->
                Jv.obj
                  [|
                    ("choiceId", Jv.of_int id);
                    ("content", Jv.of_list inline content);
                  |])
              items );
        ]
    | Remove_choices node_id ->
      obj "removeChoices" [("nodeId", Jv.of_int node_id)]
    | Mark_old -> obj "markOld" []
    | Error s -> obj "error" [("message", Jv.of_string s)]

  let choices (s : M.status) : Jv.t =
    match s with
    | Awaiting { items; _ } ->
      Jv.of_list
        (fun (o : M.offered) ->
          Jv.obj
            [|
              ("choiceId", Jv.of_int o.choice_id);
              ("label", Jv.of_string o.label);
            |])
        items
    | _ -> Jv.of_list Fun.id []

  let status (s : M.status) : Jv.t =
    Jv.of_string
      (match s with
      | Running -> "running"
      | Awaiting _ -> "awaiting"
      | Stuck _ -> "stuck"
      | Done -> "done")
end

type state = {
  mutable machine : M.machine;
  mutable game : M.game;
      (** Separate field because: during eval, the new machine will not have
          been built computed yet, whereas we want to see the latest game state
      *)
  seed : int;
  mutable rng : Random.State.t;
}

(* turn js eval errors into ocaml exceptions *)
exception Eval_error of string

let () =
  Printexc.register_printer (function Eval_error s -> Some s | _ -> None)

let eval_of_host host stref =
  let f = Jv.get host "eval" in
  fun game code ->
    (* upon eval, make the current game state visible *)
    Option.iter (fun st -> st.game <- game) !stref;
    (* this apply will invoke the handle methods, which read stref *)
    match Jv.apply f [| Jv.of_string code |] with
    | v -> FromJv.value v
    | exception Jv.Error e ->
      raise
        (Eval_error
           (Jstr.to_string (Jv.Error.name e)
           ^ ": "
           ^ Jstr.to_string (Jv.Error.message e)))

(* The handle is a stateful reference to a machine which wraps the functional core written in OCaml *)
let machine_handle (st : state) : Jv.t =
  (* methods which cause an update to the machine on the ocaml side return
    a projection of its state { status, events, choices } to the js side *)
  let result ?(extra = []) ((m, events) : M.machine * M.Event.t list) : Jv.t =
    Jv.obj
      (Array.of_list
         (extra
         @ [
             ("status", ToJv.status (M.status m));
             ("events", Jv.of_list ToJv.event events);
             ("choices", ToJv.choices (M.status m));
           ]))
  in
  let produce_result ?extra ((m, events) : M.machine * M.Event.t list) : Jv.t =
    st.machine <- m;
    st.game <- M.game m;
    result ?extra (m, events)
  in
  (* expose a replay_result to js *)
  let replay_result ({ machine; events; diverged_at } : M.replay_result) : Jv.t
      =
    let extra =
      match diverged_at with
      | None -> [("diverged", Jv.false')]
      | Some at -> [("diverged", Jv.true'); ("divergedAt", Jv.of_string at)]
    in
    produce_result ~extra (machine, events)
  in
  let reseed () = st.rng <- Random.State.make [| st.seed |] in
  Jv.obj
    [|
      ( "start",
        Jv.callback ~arity:1 (fun () -> produce_result (M.run st.machine)) );
      ( "choose",
        Jv.callback ~arity:1 (fun id ->
            produce_result (M.choose st.machine (Jv.to_int id))) );
      ( "chooseByLabel",
        Jv.callback ~arity:1 (fun label ->
            produce_result (M.choose_by_label st.machine (Jv.to_string label)))
      );
      ( "activate",
        Jv.callback ~arity:1 (fun id ->
            produce_result (M.activate st.machine (Jv.to_int id))) );
      ( "activateByLabel",
        Jv.callback ~arity:1 (fun label ->
            produce_result (M.activate_by_label st.machine (Jv.to_string label)))
      );
      ( "rewind",
        Jv.callback ~arity:1 (fun n ->
            let n = if Jv.is_none n then 1 else Jv.to_int n in
            let mach = st.machine in
            reseed ();
            produce_result (M.rewind ~n mach)) );
      ( "loadSaved",
        (* headless replay of a saved history over the same program *)
        Jv.callback ~arity:1 (fun labels ->
            let labels = Jv.to_list Jv.to_string labels in
            let mach = st.machine in
            reseed ();
            replay_result (M.load_saved mach labels)) );
      ( "hotReload",
        (* replay the session history against a newly parsed story *)
        Jv.callback ~arity:1 (fun story ->
            let program = jv_to_ocaml Fabula.Ast.program_of_yojson story in
            let mach = st.machine in
            reseed ();
            replay_result (M.hot_reload mach program)) );
      ( "status",
        Jv.callback ~arity:1 (fun () -> ToJv.status (M.status st.machine)) );
      ( "choices",
        Jv.callback ~arity:1 (fun () -> ToJv.choices (M.status st.machine)) );
      ("turns", Jv.callback ~arity:1 (fun () -> Jv.of_int (M.turns st.game)));
      ( "currentScene",
        Jv.callback ~arity:1 (fun () ->
            match M.current_section st.game with
            | None -> Jv.null
            | Some s -> Jv.of_string s) );
      ( "history",
        Jv.callback ~arity:1 (fun () ->
            Jv.of_list Jv.of_string (M.choice_history st.game)) );
      ( "turnsSince",
        Jv.callback ~arity:1 (fun s ->
            Jv.of_int (M.turns_since st.game (Jv.to_string s))) );
      ( "seen",
        Jv.callback ~arity:1 (fun s ->
            Jv.of_int (M.seen st.game (Jv.to_string s))) );
      (* the seed this world assumes (persist with saves) *)
      ("seed", Jv.callback ~arity:1 (fun () -> Jv.of_int st.seed));
      ( "random",
        Jv.callback ~arity:1 (fun () ->
            Random.State.float st.rng 1. |> Jv.of_float) );
      ( "randomIncl",
        Jv.callback ~arity:2 (fun l h ->
            let l = Jv.to_int l in
            let h = Jv.to_int h in
            Jv.of_int (l + Random.State.int st.rng (h + 1 - l))) );
      ( "randomExcl",
        Jv.callback ~arity:2 (fun l h ->
            let l = Jv.to_int l in
            let h = Jv.to_int h in
            Jv.of_int (l + Random.State.int st.rng (h - l))) );
      ( "coin",
        Jv.callback ~arity:0 (fun () -> Random.State.bool st.rng |> Jv.of_bool)
      );
    |]

let () =
  Jv.set Jv.global "Machine"
    (Jv.obj
       [|
         ( "create",
           (* create(storyJson, { eval, seed }) -> handle *)
           Jv.callback ~arity:2 (fun story host ->
               let program = jv_to_ocaml Fabula.Ast.program_of_yojson story in
               let seed = Jv.get host "seed" |> Jv.to_int in
               let stref = ref None in
               let m =
                 (* only the ref is passed in here (i.e. a knot); it's not read! *)
                 M.create { M.program; eval = eval_of_host host stref; seed }
               in
               let st =
                 {
                   machine = m;
                   game = M.game m;
                   seed;
                   rng = Random.State.make [| seed |];
                 }
               in
               stref := Some st;
               machine_handle st) );
       |])

let () =
  Jv.set Jv.global "Fable"
    (Jv.obj
       [|
         ( "parse",
           Jv.callback ~arity:1 (fun s ->
               try
                 Fabula.parse_str (Jv.to_string s)
                 |> ocaml_to_jv Fabula.program_to_yojson
               with Fabula.InputError s ->
                 Jv.throw (Jstr.of_string ("parse: " ^ s))) );
         ( "produceStyleOverride",
           Jv.callback ~arity:1 (fun fm ->
               Fabula.produce_style_override (FromJv.assoc fm) |> Jv.of_string)
         );
         ( "graph",
           Jv.callback ~arity:1 (fun s ->
               try
                 Fabula.parse_str (Jv.to_string s)
                 |> Fabula.Graph.program_graph Fabula.Graph.mermaid_renderer
                 |> Jv.of_string
               with Fabula.InputError s ->
                 Jv.throw (Jstr.of_string ("graph: " ^ s))) );
       |])
