type choice_item = {
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

and choice = {
  more : more;
  fallthrough : bool;
  items : choice_item list;
}

and cmd =
  | Para of cmd list
  | VerbatimBlock of string (* block *)
  | Verbatim of string (* inline *)
  | Text of string
  | Emph of cmd list
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
  | Choice of choice
[@@deriving
  show { with_path = false },
  yojson,
  visitors { variety = "map"; name = "map_cmd" }]

[@@@warning "-17"]

type scene = {
  name : string;
  cmds : cmd list;
}
[@@deriving
  show { with_path = false },
  yojson,
  visitors { variety = "map"; name = "map_scene" }]

type program = scene list
[@@deriving
  show { with_path = false },
  yojson,
  visitors { variety = "map"; name = "map_program" }]

type cmds = cmd list [@@deriving show { with_path = false }, yojson]
type choice_items = choice_item list [@@deriving yojson]

let _ = pp_program
