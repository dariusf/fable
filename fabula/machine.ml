open Common
open Ast

type value =
  | VUndefined
  | VBool of bool
  | VNumber of float
  | VString of string
  | VCmds of cmd list (* array of cmds that a Meta produces *)

let truthy = function
  | VUndefined -> false
  | VBool b -> b
  | VNumber f -> f <> 0. && not (Float.is_nan f)
  | VString s -> s <> ""
  | VCmds _ -> true

(* JS [v + ""] *)
let value_to_string = function
  | VUndefined -> ""
  | VBool b -> if b then "true" else "false"
  | VNumber f ->
    (* TODO: needed? *)
    (* approximates JS number formatting for the realistic range *)
    if Float.is_integer f && Float.abs f < 1e15 then Format.sprintf "%.0f" f
    else Format.sprintf "%.12g" f
  | VString s -> s
  | VCmds _ ->
    (* TODO: probably useless? *)
    "[object Object]"

module Event = struct
  type inline =
    | Text of string
    | Verbatim of string
    | Link of {
        link_id : int;
        label : string;
      }
    | Emph of inline list
  [@@deriving show { with_path = false }]

  type t =
    | Para of inline list
    | Verbatim_block of string
    | Choices of {
        node_id : int;
        items : (int * inline list) list;
      }
    | Remove_choices of int
    | Mark_old
    | Error of string
  [@@deriving show { with_path = false }]
end

module Rendering : sig
  val trim_run : Event.inline list -> Event.inline list
  val events_to_string : Event.t list -> string

  (** For choice and link labels *)
  val einlines_text : Event.inline list -> string
end = struct
  let trim_run (run : Event.inline list) : Event.inline list =
    let rec strip re = function
      | Event.Text s :: rest when is_whitespace s -> strip re rest
      | Event.Text s :: rest ->
        Event.Text (Str.replace_first (Str.regexp re) "" s) :: rest
      | l -> l
    in
    run |> strip "^[ \t\n]+" |> List.rev |> strip "[ \t\n]+$" |> List.rev

  (* TODO use a proper parser *)
  let strip_tags s = Str.global_replace (Str.regexp "<[^>]*>") "" s

  (* The plain text of a run *)
  let einlines_text (es : Event.inline list) : string =
    let buf = Buffer.create 32 in
    let rec go es =
      List.iter
        (fun (i : Event.inline) ->
          match i with
          | Text s -> Buffer.add_string buf s
          | Verbatim s -> Buffer.add_string buf (strip_tags s)
          | Link { label; _ } -> Buffer.add_string buf label
          | Emph is -> go is)
        es
    in
    go es;
    Buffer.contents buf

  let events_to_string (events : Event.t list) : string =
    (* blocks are tagged with a node id when removable (choice lists) *)
    let blocks : (int option * string) list ref = ref [] in
    let buf = Buffer.create 256 in
    let collapse_spaces s =
      Str.global_replace (Str.regexp "[ \t\n]+") " " s |> String.trim
    in
    let close_block ?id () =
      if Buffer.length buf > 0 then begin
        blocks := (id, Buffer.contents buf) :: !blocks;
        Buffer.clear buf
      end
    in
    List.iter
      (fun (e : Event.t) ->
        match e with
        | Mark_old -> ()
        | Para is ->
          Buffer.add_string buf (collapse_spaces (einlines_text is));
          close_block ()
        | Verbatim_block s ->
          close_block ();
          Buffer.add_string buf (strip_tags s);
          close_block ()
        | Choices { node_id; items } ->
          close_block ();
          List.iteri
            (fun i (_, content) ->
              if i > 0 then Buffer.add_char buf '\n';
              Buffer.add_string buf
                (Format.sprintf "%d. %s" (i + 1)
                   (collapse_spaces (einlines_text content))))
            items;
          close_block ~id:node_id ()
        | Remove_choices node_id ->
          blocks := List.filter (fun (id, _) -> id <> Some node_id) !blocks
        | Error s ->
          close_block ();
          Buffer.add_string buf ("error: " ^ s);
          close_block ())
      events;
    close_block ();
    String.concat "\n\n" (List.rev_map snd !blocks)
end

(* * The machine *)

type ctx =
  | Root  (** in a section; for Tunnel *)
  | In_para  (** open container *)
  | In_emph
  | Splice  (** nothing; for inline Meta *)

type frame = {
  instrs : cmd list;  (** instructions left to run *)
  ctx : ctx;  (** what popping the frame closes *)
}

type offered = {
  choice_id : int;
  label : string;
  content : Event.inline list;
  consumable : string option;
      (* id for keeping track of which choices are consumable *)
  code : cmd list;
  rest : cmd list;
}

type link = {
  link_kind : [ `Code | `Jump ];
  dest : string;
  label : string;
}

type status =
  | Running
  | Awaiting of {
      node_id : int;
      items : offered list; (* guaranteed not to be empty *)
    }
  | Stuck of string
  | Done

(* Machine-owned game state: persistent, snapshottable. *)
type game = {
  turns : int;
  seen_sections : int SMap.t;
  last_visited_turn : int SMap.t;
  current_section : string option;
  choice_state : SSet.t; (* consumed Consumable ids *)
  choice_history : history_entry Acc.t; (* in order *)
}

and history_entry =
  | Choice of string
  | Widget of {
      key : string;
      value : string;
    }

type inputs = {
  program : program;
  seed : int;
  eval : game -> [ `Value | `Effect ] -> string -> value;
  set_widget : string -> string -> unit;
}

type machine = {
  inputs : inputs;
  sections : cmd list SMap.t;
  stack : frame list;
      (** Reified continuation as stack of frames. Top = current *)
  open_runs : Event.inline Acc.t list;
      (** A stack of buffered, partial outputs, with one entry corresponding to
          each open Para or Emph. There can be Splice (inline Meta in a
          paragraph) or Root (Tunnel) frames above, which is the reason this is
          a separate field *)
  status : status;
  game : game;
  links : link IMap.t; (* live across turns; machine-level rather than game *)
  next_id : int;
  events : Event.t Acc.t; (* accumulated partial outputs *)
}

let emit m e =
  (* emitting an error will not halt the machine, which is usually a problem, as errors are emitted on programmer error (misuse of this API) *)
  { m with events = Acc.add m.events e }

(* early commit of the open runs: before a jump or tunnel moves control
   away, and before a halt, so buffered text is not abandoned *)
let flush_runs m =
  let paras = ref [] in
  let rec loop frames runs carry =
    match (frames, runs) with
    | { ctx = In_emph; _ } :: fs, run :: rs ->
      Acc.empty :: loop fs rs [Event.Emph (Acc.to_list run @ carry)]
    | { ctx = In_para; _ } :: fs, run :: rs ->
      paras := (Acc.to_list run @ carry) :: !paras;
      Acc.empty :: loop fs rs []
    | { ctx = Root | Splice; _ } :: fs, rs -> loop fs rs carry
    | [], rs -> rs
    | _ -> failwith "machine invariant: frame without open run"
  in
  let runs = loop m.stack m.open_runs [] in
  (* !paras is outermost-first, i.e. DOM insertion order *)
  let m =
    List.fold_left
      (fun m run ->
        match Rendering.trim_run run with
        | [] -> m
        | run -> emit m (Event.Para run))
      m !paras
  in
  { m with open_runs = runs }

let halt m msg =
  let m = flush_runs m in
  let m = emit m (Event.Error msg) in
  { m with status = Stuck msg }

let fresh_id m = ({ m with next_id = m.next_id + 1 }, m.next_id)

let eval_safe m want code =
  match m.inputs.eval m.game want code with
  | v -> Ok v
  | exception e -> Error (describe_exn e)

let push_inline m i =
  match m.open_runs with
  | run :: rest -> { m with open_runs = Acc.add run i :: rest }
  | [] ->
    (* stray inline at block level; today's markdown never produces this *)
    halt m "inline outside paragraph"

(* Section-visit bookkeeping (the on_section_visit callback of interpret.js):
   fires on start, Jump, JumpDynamic, Tunnel. *)
let visit_section m section =
  let g = m.game in
  let seen = Option.value ~default:0 (SMap.find_opt section g.seen_sections) in
  {
    m with
    game =
      {
        g with
        seen_sections = SMap.add section (seen + 1) g.seen_sections;
        current_section = Some section;
        last_visited_turn = SMap.add section g.turns g.last_visited_turn;
      };
  }

let default_game =
  {
    turns = 0;
    seen_sections = SMap.empty;
    last_visited_turn = SMap.empty;
    current_section = None;
    choice_state = SSet.empty;
    choice_history = Acc.empty;
  }

let create (inputs : inputs) : machine =
  let sections =
    (* first occurrence wins, as with the old assoc list *)
    List.fold_left
      (fun acc (s : scene) ->
        if SMap.mem s.name acc then acc else SMap.add s.name s.cmds acc)
      SMap.empty inputs.program.scenes
  in
  let m =
    {
      inputs;
      sections;
      stack = [];
      open_runs = [];
      status = Done;
      game = default_game;
      links = IMap.empty;
      next_id = 0;
      events = Acc.empty;
    }
  in
  match inputs.program.scenes with
  | [] -> m
  | section :: _ ->
    let m = visit_section m section.name in
    { m with stack = [{ instrs = section.cmds; ctx = Root }]; status = Running }

(* Pops the top (exhausted) frame, closing what it opened. *)
let pop_frame m frame rest =
  match frame.ctx with
  | Root ->
    if rest = [] then { m with stack = []; status = Done }
    else { m with stack = rest } (* tunnel return: resume the caller *)
  | Splice -> { m with stack = rest }
  | In_para ->
    (match m.open_runs with
    | run :: runs ->
      let m = { m with stack = rest; open_runs = runs } in
      (match Rendering.trim_run (Acc.to_list run) with
      | [] -> m
      | run -> emit m (Event.Para run))
    | [] -> failwith "machine invariant: In_para frame without open run")
  | In_emph ->
    (match m.open_runs with
    | run :: runs ->
      let m = { m with stack = rest; open_runs = runs } in
      push_inline m (Event.Emph (Acc.to_list run))
    | [] -> failwith "machine invariant: In_emph frame without open run")

let do_jump m kind section_name =
  match SMap.find_opt section_name m.sections with
  | None -> halt m (Format.sprintf "%s: section %s not found" kind section_name)
  | Some cmds ->
    let m = flush_runs m in
    let m = visit_section m section_name in
    {
      m with
      stack = [{ instrs = cmds; ctx = Root }];
      open_runs = [];
      status = Running;
    }

(* Renders choice/link label content ([item.initial]) to a string via the
   inline machinery. Interpolations run; anything block-level is a
   compile-side impossibility. *)
let rec label_inlines m (cmds : cmd list) :
    (machine * Event.inline list, machine) result =
  List.fold_left
    (fun acc c ->
      match acc with
      | Error _ -> acc
      | Ok (m, is) ->
        (match c with
        | Text s -> Ok (m, Event.Text s :: is)
        | Verbatim s -> Ok (m, Event.Verbatim s :: is)
        | Break -> Ok (m, Event.Text " " :: is)
        | Emph cs ->
          (match label_inlines m cs with
          | Ok (m, inner) -> Ok (m, Event.Emph inner :: is)
          | Error m -> Error m)
        | Interpolate code ->
          (match eval_safe m `Value code with
          | Ok v -> Ok (m, Event.Text (value_to_string v) :: is)
          | Error e ->
            Error
              (halt m
                 (Format.sprintf "Interpolate: error when executing %s: %s" code
                    e)))
        | c ->
          Error
            (halt m
               ("unsupported instruction in choice label: " ^ Ast.show_cmd c))))
    (Ok (m, []))
    cmds
  |> Result.map (fun (m, is) -> (m, List.rev is))

(* * Choice offering: guard orchestration, sticky/consumable, otherwise,
   fallthrough, more *)

exception Halt_exn of machine

let offer_choice m (c : choice) : machine =
  try
    (* expand `more` recursively from the referenced sections *)
    let extra =
      try
        Compile.recursively_add_choices
          (fun s ->
            match SMap.find_opt s m.sections with
            | Some cmds -> cmds
            | None ->
              failwith (s ^ " is not a section with a single choice in it"))
          c.more
      with Failure e -> raise (Halt_exn (halt m e))
    in
    let all_items = c.items @ extra in
    let m = ref m in
    let passes_guards (item : choice_item) =
      let internal_ok =
        match item.kind with
        | Sticky -> true
        | Consumable id -> not (SSet.mem id !m.game.choice_state)
      in
      internal_ok
      && List.for_all
           (fun g ->
             match eval_safe !m `Value g with
             | Ok v -> truthy v
             | Error e ->
               raise
                 (Halt_exn
                    (halt !m
                       (Format.sprintf "guard: error when executing %s: %s" g e))))
           item.guard
    in
    let generate (item : choice_item) : offered =
      let content =
        match label_inlines !m item.initial with
        | Ok (m', is) ->
          m := m';
          Rendering.trim_run is
        | Error m' -> raise (Halt_exn m')
      in
      let m', id = fresh_id !m in
      m := m';
      {
        choice_id = id;
        label = Rendering.einlines_text content;
        content;
        consumable =
          (match item.kind with Sticky -> None | Consumable id -> Some id);
        code = item.code;
        rest = item.rest;
      }
    in
    let normal, otherwises =
      List.partition (fun i -> not i.otherwise) all_items
    in
    let offered = List.filter passes_guards normal |> List.map generate in
    let offered =
      if offered = [] then
        List.filter passes_guards otherwises |> List.map generate
      else offered
    in
    let m = !m in
    if offered = [] then
      if c.fallthrough then m (* continue with the rest of the frame *)
      else { m with status = Done } (* stop intentionally, as today *)
    else begin
      let m, node_id = fresh_id m in
      let m =
        emit m
          (Event.Choices
             {
               node_id;
               items = List.map (fun o -> (o.choice_id, o.content)) offered;
             })
      in
      { m with status = Awaiting { node_id; items = offered } }
    end
  with Halt_exn m -> m

(* * Meta *)

(* [Fable.parse] minus frontmatter extraction (meta results never carry
   frontmatter). Machine can't depend on the library's main module. *)
let parse_sections (s : string) : Ast.scene list =
  Cmarkit.Doc.of_string s |> Compile.to_scenes

let do_meta m kind code =
  let kind_s = match kind with `Meta -> "Meta" | `Block -> "MetaBlock" in
  let err m e =
    halt m (Format.sprintf "%s: error when executing %s: %s" kind_s code e)
  in
  match eval_safe m `Value code with
  | Error e -> err m e
  | Ok v ->
    let cmds_result =
      match v with
      | VCmds cs -> Ok cs
      | v ->
        (match parse_sections (value_to_string v) with
        | [] -> Ok []
        | section :: _ -> Ok section.cmds
        | exception e -> Error (describe_exn e))
    in
    (match cmds_result with
    | Error e -> err m e
    | Ok [] -> m
    | Ok (first :: _ as cmds) ->
      (match kind with
      | `Block ->
        (* splice the blocks at the current position *)
        { m with stack = { instrs = cmds; ctx = Splice } :: m.stack }
      | `Meta ->
        (* the result is assumed to be a single Para whose children are
           spliced into the open inline run *)
        (match first with
        | Para children ->
          { m with stack = { instrs = children; ctx = Splice } :: m.stack }
        | _ -> err m "result of inline meta is not a paragraph")))

let step (m : machine) : machine =
  match m.stack with
  | [] -> { m with status = Done }
  | ({ instrs = []; _ } as frame) :: rest -> pop_frame m frame rest
  | ({ instrs = instr :: instrs; _ } as frame) :: rest ->
    let m = { m with stack = { frame with instrs } :: rest } in
    let inline_ctx =
      (* Splice frames inherit the enclosing context: inline iff an
         inline run is open *)
      match frame.ctx with
      | In_para | In_emph -> true
      | Root -> false
      | Splice -> m.open_runs <> []
    in
    (match instr with
    | Para [] -> m
    | Para cmds ->
      if may_have_text (Para cmds) then
        {
          m with
          stack = { instrs = cmds; ctx = In_para } :: m.stack;
          open_runs = Acc.empty :: m.open_runs;
        }
      else
        (* no text: execute the children without opening a paragraph *)
        { m with stack = { instrs = cmds; ctx = Splice } :: m.stack }
    | Emph cmds ->
      if inline_ctx then
        {
          m with
          stack = { instrs = cmds; ctx = In_emph } :: m.stack;
          open_runs = Acc.empty :: m.open_runs;
        }
      else halt m "emphasis outside paragraph"
    | Text s ->
      if inline_ctx then push_inline m (Event.Text s)
      else if is_whitespace s then m
      else halt m "text outside paragraph"
    | Verbatim s ->
      if inline_ctx then push_inline m (Event.Verbatim s)
      else emit m (Event.Verbatim_block s)
    | Break -> if inline_ctx then push_inline m (Event.Text " ") else m
    | VerbatimBlock s -> emit m (Event.Verbatim_block s)
    | Run code ->
      (match eval_safe m `Effect code with
      | Ok _ -> m
      | Error e ->
        halt m (Format.sprintf "Run: error when executing %s: %s" code e))
    | Interpolate code ->
      (match eval_safe m `Value code with
      | Ok v -> push_inline m (Event.Text (value_to_string v))
      | Error e ->
        halt m
          (Format.sprintf "Interpolate: error when executing %s: %s" code e))
    | LinkCode (label, dest) | LinkJump (label, dest) ->
      let link_kind = match instr with LinkCode _ -> `Code | _ -> `Jump in
      let m, id = fresh_id m in
      let m =
        { m with links = IMap.add id { link_kind; dest; label } m.links }
      in
      push_inline m (Event.Link { link_id = id; label })
    | Jump section -> do_jump m "Jump" section
    | JumpDynamic code ->
      (match eval_safe m `Value code with
      | Ok v -> do_jump m "JumpDynamic" (value_to_string v)
      | Error e ->
        halt m
          (Format.sprintf "JumpDynamic: error when executing %s: %s" code e))
    | Tunnel section ->
      (match SMap.find_opt section m.sections with
      | None -> halt m (Format.sprintf "Tunnel: section %s not found" section)
      | Some cmds ->
        let m = flush_runs m in
        let m = visit_section m section in
        { m with stack = { instrs = cmds; ctx = Root } :: m.stack })
    | Meta code -> do_meta m `Meta code
    | MetaBlock code -> do_meta m `Block code
    | Choice c -> offer_choice m c)

let run (m : machine) : machine * Event.t list =
  let rec loop m = if m.status = Running then loop (step m) else m in
  let m = loop m in
  ({ m with events = Acc.empty }, Acc.to_list m.events)

(* * Interaction entry points *)

let interact m =
  (* the on_interact callback: a turn passes *)
  { m with game = { m.game with turns = m.game.turns + 1 } }

let choose (m : machine) (choice_id : int) : machine * Event.t list =
  match m.status with
  | Awaiting { node_id; items } ->
    (match List.find_opt (fun o -> o.choice_id = choice_id) items with
    | None -> run (halt m (Format.sprintf "no such choice %d" choice_id))
    | Some o ->
      let m = emit m Event.Mark_old in
      let m =
        {
          m with
          game =
            {
              m.game with
              choice_history = Acc.add m.game.choice_history (Choice o.label);
              choice_state =
                (match o.consumable with
                | Some id -> SSet.add id m.game.choice_state
                | None -> m.game.choice_state);
            };
        }
      in
      let m = interact m in
      let m = emit m (Event.Remove_choices node_id) in
      let m =
        {
          m with
          status = Running;
          stack = { instrs = o.code @ o.rest; ctx = Splice } :: m.stack;
        }
      in
      run m)
  | _ -> run (halt m "not awaiting a choice")

let widget_input (m : machine) ~key ~value : machine =
  m.inputs.set_widget key value;
  {
    m with
    game =
      {
        m.game with
        choice_history = Acc.add m.game.choice_history (Widget { key; value });
      };
  }

let choose_by_label (m : machine) (label : string) : machine * Event.t list =
  match m.status with
  | Awaiting { items; _ } ->
    (match
       List.find_opt
         (fun (o : offered) -> String.trim o.label = String.trim label)
         items
     with
    | Some o -> choose m o.choice_id
    | None -> run (halt m (Format.sprintf "no choice labelled %S" label)))
  | _ -> run (halt m "not awaiting a choice")

let activate (m : machine) (link_id : int) : machine * Event.t list =
  match IMap.find_opt link_id m.links with
  | None -> run (halt m (Format.sprintf "no such link %d" link_id))
  | Some { link_kind; dest; _ } ->
    let m = interact m in
    (match link_kind with
    | `Code ->
      (* as today: link code is `dest()`; output-free, choices stay live *)
      (match eval_safe m `Effect (dest ^ "()") with
      | Ok _ -> run m
      | Error e ->
        run
          (halt m (Format.sprintf "Run: error when executing %s(): %s" dest e)))
    | `Jump -> run (do_jump m "Jump" dest))

let activate_by_label (m : machine) (label : string) : machine * Event.t list =
  let matching =
    IMap.fold
      (fun id l acc ->
        if String.trim l.label = String.trim label then Some id else acc)
      m.links None
  in
  match matching with
  | Some id -> activate m id
  | None -> run (halt m (Format.sprintf "no link labelled %S" label))

type replay_result = {
  machine : machine;
  events : Event.t list;
  diverged_at : string option;
}

let choose_many (m : machine) (entries : history_entry list) : replay_result =
  let m, events = run m in
  let rec loop m events entries =
    match entries with
    | [] -> { machine = m; events; diverged_at = None }
    | Widget { key; value } :: rest ->
      loop (widget_input m ~key ~value) events rest
    | Choice label :: rest ->
      let offered =
        match m.status with
        | Awaiting { items; _ } ->
          List.exists
            (fun (o : offered) -> String.trim o.label = String.trim label)
            items
        | _ -> false
      in
      if not offered then { machine = m; events; diverged_at = Some label }
      else begin
        let m, evs = choose_by_label m label in
        loop m (events @ evs) rest
      end
  in
  loop m events entries

let load_saved (m : machine) (entries : history_entry list) : replay_result =
  choose_many (create m.inputs) entries

let hot_reload (m : machine) (program : program) : replay_result =
  choose_many
    (create { m.inputs with program })
    (Acc.to_list m.game.choice_history)

(* a turn is the widget entries recorded for a choice, followed by the choice *)
let drop_turns n (history : history_entry list) : history_entry list =
  let rec drop n rev =
    if n = 0 then rev
    else
      match rev with
      | [] -> []
      | Choice _ :: rest -> drop (n - 1) (drop_widgets rest)
      | Widget _ :: rest -> drop n rest
  and drop_widgets = function
    | Widget _ :: rest -> drop_widgets rest
    | rest -> rest
  in
  List.rev (drop n (List.rev history))

let rewind ?(n = 1) (m : machine) : machine * Event.t list =
  let history = Acc.to_list m.game.choice_history in
  let { machine; events; diverged_at } = load_saved m (drop_turns n history) in
  match diverged_at with
  | None -> (machine, events)
  | Some at ->
    let machine = halt machine (Format.sprintf "rewind: diverged at %S" at) in
    let machine, evs = run machine in
    (machine, events @ evs)

let skip_until needle m =
  (* why this "lasso" structure? because the machine is not initially waiting, so there's no choice to start the loop with until after first running it *)
  let m, evs = run m in
  let found = contains_substring ~sub:needle (Rendering.events_to_string evs) in
  if found then (m, evs)
  else
    let rec loop fuel needle acc m =
      if fuel <= 0 then (m, acc)
      else
        match m.status with
        | Awaiting { items; node_id = _ } ->
          (* hd is safe since Awaiting guarantees not empty *)
          (* always picks first item *)
          let it = List.hd items in
          let m, evs = choose m it.choice_id in
          (* Matching is per-segment for efficiency. This means matches cannot span segments (okay because typical use is to match non-choice text). Also can match choice text which might later be removed from the full transcript *)
          let found =
            contains_substring ~sub:needle (Rendering.events_to_string evs)
          in
          if found then (m, evs :: acc)
          else
            (* possible nontermination, which is accepted *)
            loop (fuel - 1) needle (evs :: acc) m
        | Running -> assert false
        | Done | Stuck _ ->
          (* does not guarantee finding the text, does not match errors *)
          (m, acc)
    in
    let m, acc = loop 1000 needle [] m in
    (m, evs @ List.concat (List.rev acc))

let apply_inputs (m : machine) (entries : history_entry list) :
    machine * Event.t list =
  let m, evs =
    List.fold_left
      (fun (m, acc) entry ->
        match entry with
        | Widget { key; value } -> (widget_input m ~key ~value, acc)
        | Choice label ->
          let m, evs = choose_by_label m label in
          (m, Acc.add_all evs acc))
      (m, Acc.empty) entries
  in
  (m, Acc.to_list evs)

let status m = m.status
let game m = m.game
let turns (g : game) = g.turns
let current_section (g : game) = g.current_section
let history (g : game) = Acc.to_list g.choice_history

let choice_history (g : game) =
  List.filter_map
    (function Choice l -> Some l | Widget _ -> None)
    (Acc.to_list g.choice_history)

let turns_since (g : game) section =
  g.turns - Option.value ~default:0 (SMap.find_opt section g.last_visited_turn)

let seen (g : game) section =
  Option.value ~default:0 (SMap.find_opt section g.seen_sections)

let canned_eval canned _g _want code =
  match List.assoc_opt code canned with
  | Some v -> v
  | None -> failwith (Format.sprintf "eval stub: unknown code %S" code)

let program_of_str src : program =
  { frontmatter = []; scenes = parse_sections src }

let check_inlines ?(canned = []) src =
  let eval = canned_eval canned in
  let program = program_of_str src in
  let _, ev =
    run (create { program; seed = 0; eval; set_widget = (fun _ _ -> ()) })
  in
  ev |> List.iter (fun e -> print_endline (Event.show e));
  Format.printf "---@.";
  ev |> Rendering.events_to_string |> print_string

let%expect_test "spaces are kept as written across an interpolation" =
  check_inlines ~canned:[("n", VNumber 3.)] {|You have `$n` coins.|};
  [%expect
    {|
    (Para [(Text "You have "); (Text "3"); (Text " coins.")])
    ---
    You have 3 coins.
    |}]

let%expect_test "a soft break renders as a space" =
  check_inlines "first line\nsecond line";
  [%expect
    {|
    (Para [(Text "first line"); (Text " "); (Text "second line")])
    ---
    first line second line
    |}]

let%expect_test
    "breaks and spaces around code compile differently but render the same" =
  check_inlines ~canned:[("0", VUndefined)] "a\n`0`\nc";
  [%expect
    {|
    (Para [(Text "a"); (Text " "); (Text " "); (Text "c")])
    ---
    a c
    |}];
  check_inlines ~canned:[("0", VUndefined)] "a `0` c";
  [%expect {|
    (Para [(Text "a "); (Text " c")])
    ---
    a c
    |}]

let%expect_test
    "an empty interpolation leaves a double space that the text renderer \
     collapses" =
  check_inlines ~canned:[("nothing", VString "")] {|before `$nothing` after|};
  [%expect
    {|
    (Para [(Text "before "); (Text ""); (Text " after")])
    ---
    before after
    |}]

let drive ?(canned = []) src labels =
  let m =
    create
      {
        program = program_of_str src;
        eval = canned_eval canned;
        seed = 0;
        set_widget = (fun _ _ -> ());
      }
  in
  let m, events = run m in
  List.fold_left
    (fun (m, events) label ->
      let m, evs = choose_by_label m label in
      (m, events @ evs))
    (m, events) labels

let check ?canned src labels =
  let _m, events = drive ?canned src labels in
  print_string (Rendering.events_to_string events)

let%expect_test "paragraphs and emphasis" =
  check {|# start

First.

Plain *emphasized* after.
|} [];
  [%expect {|
    First.

    Plain emphasized after.
    |}]

let%expect_test "jump abandons rest of section" =
  check {|# start

Before. `->other`

Never shown.

# other

Landed.
|} [];
  [%expect {|
    Before.

    Landed.
    |}]

let%expect_test "tunnel resumes caller" =
  check {|# start

Before. `tunnel other`

After.

# other

Inside.
|} [];
  [%expect {|
    Before.

    Inside.

    After.
    |}]

let%expect_test "interpolate and run" =
  check
    ~canned:[("name", VString "Iris"); ("setup()", VUndefined)]
    {|# start

```
setup()
```

Hello `$name`.
|} [];
  [%expect {| Hello Iris. |}]

let%expect_test "jump dynamic" =
  check
    ~canned:[("dest", VString "other")]
    {|# start

Going. `->$dest`

# other

There.
|} [];
  [%expect {|
    Going.

    There.
    |}]

let%expect_test "inline meta splices into run" =
  check
    ~canned:[("greet()", VString "well met")]
    {|# start

Hail, `~greet()` friend.
|} [];
  [%expect {| Hail, well met friend. |}]

let%expect_test "choose and continue" =
  check
    {|# start

Pick one.

- Go left

  You went left.

- Go right

  You went right.

Either way.
|}
    ["Go right"];
  [%expect {|
    Pick one.

    You went right.

    Either way.
    |}]

let%expect_test "offered choices render" =
  check {|# start

- Go left
- Go right
|} [];
  [%expect {|
    1. Go left
    2. Go right
    |}]

let%expect_test "consumable is consumed" =
  check
    {|# start

- Ask about the weather

  Rainy. `->start`

- Leave

  Bye.
|}
    ["Ask about the weather"; "Leave"];
  [%expect {|
    Rainy.

    Bye.
    |}]

let%expect_test "otherwise fires when guards fail" =
  check
    ~canned:[("hasKey", VBool false)]
    {|# start

- `?hasKey` Secret door

  In.

- `otherwise` Look around

  Nothing here.
|}
    ["Look around"];
  [%expect {| Nothing here. |}]

let%expect_test "replay divergence" =
  let m =
    create
      {
        program = program_of_str {|# start

- Yes

  Yay.
|};
        eval = canned_eval [];
        seed = 0;
        set_widget = (fun _ _ -> ());
      }
  in
  print_endline
    ([%show: string option] (choose_many m [Choice "No"]).diverged_at);
  [%expect {| (Some "No") |}]

let%expect_test "rewind" =
  let src = {|# start

Hi

- `sticky` Onward `->start`
- Stop

  Done.
|} in
  let m, events = drive src ["Onward"; "Onward"] in
  let g = game m in
  Format.printf "history %s, turns %d@."
    (String.concat "," (choice_history g))
    (turns g);
  Format.printf "%s@." (Rendering.events_to_string events);
  let m', events' = rewind ~n:1 m in
  let g' = game m' in
  Format.printf "history %s, turns %d@."
    (String.concat "," (choice_history g'))
    (turns g');
  Format.printf "%s@." (Rendering.events_to_string events');
  [%expect
    {|
    history Onward,Onward, turns 2
    Hi

    Hi

    Hi

    1. Onward
    2. Stop
    history Onward, turns 1
    Hi

    Hi

    1. Onward
    2. Stop
    |}]

let%expect_test "apply_inputs applies widget entries before the choice" =
  let src =
    {|# start

<select id="mood"></select>

- Continue

You felt `$widgets.mood`.
|}
  in
  let applied = ref [] in
  let m =
    create
      {
        program = program_of_str src;
        eval = canned_eval [("widgets.mood", VString "tense")];
        seed = 0;
        set_widget = (fun k v -> applied := (k, v) :: !applied);
      }
  in
  let m, _ = run m in
  let m, evs =
    apply_inputs m [Widget { key = "mood"; value = "tense" }; Choice "Continue"]
  in
  Format.printf "applied %s@."
    (String.concat "," (List.rev_map (fun (k, v) -> k ^ "=" ^ v) !applied));
  Format.printf "history %s@."
    (String.concat ","
       (List.map
          (function
            | Choice l -> l | Widget { key; value } -> key ^ "=" ^ value)
          (history (game m))));
  print_string (Rendering.events_to_string evs);
  [%expect
    {|
    applied mood=tense
    history mood=tense,Continue
    You felt tense.
    |}]

let%expect_test "widgets are recorded per turn and rewound with it" =
  let src = {|# start

Hi

- `sticky` Onward `->start`
- Stop

  Done.
|} in
  let applied = ref [] in
  let m =
    create
      {
        program = program_of_str src;
        eval = canned_eval [];
        seed = 0;
        set_widget = (fun k v -> applied := (k, v) :: !applied);
      }
  in
  let show_history g =
    String.concat ","
      (List.map
         (function Choice l -> l | Widget { key; value } -> key ^ "=" ^ value)
         (history g))
  in
  let { machine = m; diverged_at; _ } =
    choose_many m
      [
        Widget { key = "mood"; value = "calm" };
        Choice "Onward";
        Widget { key = "mood"; value = "tense" };
        Widget { key = "name"; value = "x" };
        Choice "Onward";
      ]
  in
  Format.printf "diverged %a@."
    (Format.pp_print_option Format.pp_print_string)
    diverged_at;
  Format.printf "history %s, turns %d@."
    (show_history (game m))
    (turns (game m));
  Format.printf "applied %s@."
    (String.concat "," (List.rev_map (fun (k, v) -> k ^ "=" ^ v) !applied));
  let m', _ = rewind ~n:1 m in
  Format.printf "history %s, turns %d@."
    (show_history (game m'))
    (turns (game m'));
  let m'', _ = rewind ~n:1 m' in
  Format.printf "history %s, turns %d@."
    (show_history (game m''))
    (turns (game m''));
  [%expect
    {|
    diverged
    history mood=calm,Onward,mood=tense,name=x,Onward, turns 2
    applied mood=calm,mood=tense,name=x
    history mood=calm,Onward, turns 1
    history , turns 0
    |}]

let%expect_test "section-visit and turn bookkeeping" =
  let m, _ =
    drive
      {|# start

Hi. `tunnel other`

- `sticky` Wait `->start`
- End

  Fin.

# other

Aside.
|}
      ["Wait"; "End"]
  in
  let g = game m in
  Format.printf "other=%d start=%d turns=%d" (seen g "other") (seen g "start")
    (turns g);
  [%expect {| other=2 start=2 turns=2 |}]
