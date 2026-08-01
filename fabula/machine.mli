(** A Fable interpreter *)
type machine

(** Machine state that user code may observe *)
type game

(** Possible shapes of values produced by evaluation of user code *)
type value =
  | VUndefined
  | VBool of bool
  | VNumber of float
  | VString of string
  | VCmds of Ast.cmds  (** result of a Meta *)

(** A machine is created from an [origin]: the inputs required to build its
    initial state. *)
type origin = {
  program : Ast.program;
  seed : int;  (** for determinim *)
  eval : game -> string -> value;
      (** the capability to evaluate JS, which may observe some game state *)
}

val create : origin -> machine

(** Instead of performing side effects, the machine emits a trace of events, to
    be consumed by a renderer. It runs synchronously and stops when the program
    ends, or input is required. In the latter case, the events contain ids which
    allow providing responses. *)
module Event : sig
  (** Rendered inline content, with explicit spaces *)
  type inline =
    | Text of string
    | Space
    | Verbatim of string
    | Link of {
        link_id : int;  (** link ids persist for the machine's lifetime *)
        label : string;
      }
    | Emph of inline list

  type t =
    | Para of inline list
    | Verbatim_block of string
    | Choices of {
        node_id : int;
        items : (int * inline list) list;
            (** (choice_id, choice item content). choice ids are valid only
                while a choice is active *)
      }
    | Remove_choices of int (* node_id *)
    | Mark_old (* everything before this point is history *)
    | Error of string

  val show : t -> string
  val pp : Format.formatter -> t -> unit
end

val run : machine -> machine * Event.t list

(** Takes a choice_id. Produces an Error event if the choice is invalid. *)
val choose : machine -> int -> machine * Event.t list

val choose_by_label : machine -> string -> machine * Event.t list

(** Takes a link_id *)
val activate : machine -> int -> machine * Event.t list

(** The most recently rendered matching link wins. *)
val activate_by_label : machine -> string -> machine * Event.t list

(** Runs until the string is found or the machine gets stuck *)
val automatically_make_choices_until :
  string -> machine -> machine * Event.t list

(** * Replay and rewind *)

type replay_result = {
  machine : machine;
  events : Event.t list;
  diverged_at : string option;
}

(** Taking a sequence of choices may lead to "divergence" (in the hot reloading
    sense, not nontermination), where a choice which was made in a previous
    version of the program can no longer be made. Other operations are built on
    this. *)
val choose_many : machine -> string list -> replay_result

(** Load from a saved history, typically at startup. *)
val load_saved : machine -> string list -> replay_result

(** Replay this machine's choice history against a new program, usually the
    result of an edit *)
val hot_reload : machine -> Ast.program -> replay_result

(** Go back [n] choices. Produces a machine in that state, and the entire trace
    required to render it, so re-rendering will replay side effects. *)
val rewind : ?n:int -> machine -> machine * Event.t list

(** Ways to query the state of the machine *)

type offered = {
  choice_id : int;
  label : string;
  content : Event.inline list;
  consumable : string option;
  code : Ast.cmds;
  rest : Ast.cmds;
}

(** The yielded state of the machine *)
type status =
  | Running  (** still stepping synchronously; cannot be observed *)
  | Awaiting of {
      node_id : int;
      items : offered list;
    }
  | Stuck of string  (** error message *)
  | Done

val status : machine -> status
val game : machine -> game

(** How many turns have passed (incremented on choice or link) *)
val turns : game -> int

val current_section : game -> string option
val choice_history : game -> string list

(** Turns elapsed since a section was last visited *)
val turns_since : game -> string -> int

(** How many times a section has been visited *)
val seen : game -> string -> int

(** * Testing *)

(** Textual rendering of an event log. Paragraphs are separated by blank lines.
    Choices render as a numbered list. Remove_choices is applied. *)

module Rendering : sig
  val events_to_string : Event.t list -> string
end
