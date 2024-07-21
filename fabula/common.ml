(** A write-only list that supports efficient accumulation from the back *)
module Acc : sig
  type 'a t

  val empty : 'a t
  val add : 'a -> 'a t -> 'a t
  val plus : 'a t -> 'a t -> 'a t
  val add_all : 'a list -> 'a t -> 'a t
  val to_list : 'a t -> 'a list
  val change_last : ('a -> 'a) -> 'a t -> 'a t
end = struct
  type 'a t = 'a list

  let empty = []
  let add = List.cons
  let add_all xs t = List.fold_left (Fun.flip List.cons) t xs
  let plus = ( @ )
  let to_list = List.rev
  let change_last f xs = match xs with [] -> [] | x :: ys -> f x :: ys
end

let read_file filename =
  let ch = open_in_bin filename in
  let s = really_input_string ch (in_channel_length ch) in
  close_in ch;
  s

module SSet = struct
  include Set.Make (String)

  let concat xs = List.fold_right union xs empty
  let concat_map f xs = concat (List.map f xs)
end

let show_inline i =
  Format.printf "%s@."
    (Cmarkit_html.of_doc ~safe:true
       (Cmarkit.Doc.make
          Cmarkit.Block.(Paragraph (Paragraph.make i, Cmarkit.Meta.none))))

let show_block b =
  Format.printf "%s@." (Cmarkit_html.of_doc ~safe:true (Cmarkit.Doc.make b))

module SMap = struct
  include Map.Make (String)

  let pp pp_v fmt map =
    Format.fprintf fmt "@[<v 0>{@;<0 2>@[<v 0>%a@]@,}@]"
      (Format.pp_print_list
         ~pp_sep:(fun fmt () -> Format.fprintf fmt ",@ ")
         (fun fmt (k, v) -> Format.fprintf fmt "%s: %a" k pp_v v))
      (bindings map)
end

let strip_prefix n s = String.trim (String.sub s n (String.length s - n))
let is_whitespace s = String.equal (String.trim s) ""
let if_exn_then ex f = try f () with _ -> raise ex
let ( let@ ) f x = f x
