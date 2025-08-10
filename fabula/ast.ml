type choice = {
  guard : string list;
  otherwise : bool;
  initial : cmd list;
  code : cmd list;
  rest : cmd list;
  kind : choice_kind;
}

and choice_kind =
  | Sticky
  | Consumable of string

and more = (string * string) list

and cmd =
  | Para of cmd list
  | VerbatimBlock of string (* block *)
  | Verbatim of string (* inline *)
  | Text of string
  | Break
  | LinkCode of string * string (* for links like [text](!id) *)
  | LinkJump of string * string (* for links like [text](#id) *)
  | Run of string
  | Interpolate of string
  | Meta of string
  | MetaBlock of string
  | Jump of string
  | Tunnel of string
  | JumpDynamic of string
  | Choices of more * choice list
[@@deriving show { with_path = false }, yojson]

type scene = {
  name : string;
  cmds : cmd list;
}
[@@deriving show { with_path = false }, yojson]

type program = scene list [@@deriving show { with_path = false }, yojson]
type cmds = cmd list [@@deriving show { with_path = false }, yojson]
type choices = choice list [@@deriving yojson]

let _ = pp_program
