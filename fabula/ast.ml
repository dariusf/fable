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

type frontmatter = (string * string) list
[@@deriving
  show { with_path = false },
  visitors { variety = "map"; name = "map_frontmatter" }]

let frontmatter_to_yojson (l : frontmatter) : Yojson.Safe.t =
  `Assoc (List.map (fun (k, v) -> (k, `String v)) l)

let frontmatter_of_yojson (json : Yojson.Safe.t) =
  match json with
  | `Assoc l ->
    let res =
      List.fold_left
        (fun acc (k, v) ->
          match (acc, v) with
          | Ok acc, `String v -> Ok ((k, v) :: acc)
          | (Error _ as e), _ -> e
          | _, _ -> Error "Expected string value in association object")
        (Ok []) l
    in
    Result.map List.rev res
  | _ -> Error "Expected JSON object for association list"

type scenes = scene list
[@@deriving
  show { with_path = false },
  yojson,
  visitors { variety = "map"; name = "map_scenes" }]

type program = {
  frontmatter : frontmatter;
  scenes : scenes;
}
[@@deriving
  show { with_path = false },
  yojson,
  visitors { variety = "map"; name = "map_program" }]

type cmds = cmd list [@@deriving show { with_path = false }, yojson]
type choice_items = choice_item list [@@deriving yojson]

let _ = pp_program

(* Overapproximate check for whether a command produces text *)
let rec may_have_text (s : cmd) =
  match s with
  | Para p | Emph p -> List.exists may_have_text p
  | Verbatim t | VerbatimBlock t | Text t -> String.length (String.trim t) > 0
  | Break | LinkCode _ | LinkJump _ | Interpolate _ -> true
  | Choice c -> (not (List.is_empty c.more)) || not (List.is_empty c.items)
  | Meta _ | MetaBlock _ ->
    (* overapproximation *)
    true
  | Run _ | Tunnel _ | Jump _ | JumpDynamic _ -> false
