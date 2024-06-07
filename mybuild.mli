
(** Extract version information from VCS (git) *)
module Version :
sig
(** specify [git_dir] to prevent git from recursing to the root of filesystem if there is no .git subdirectory *)
val git_describe : ?git_dir:string -> ?dirty:string -> unit -> string

(** Save extracted version into specified OCaml source file, as [let id = <detected version>]
  @param default substitute for version if VCS information is not available, will be inserted without any quoting, defaults to ["<unknown>"]
  @param identify whether to include username and hostname into generated file (default: false)
*)
val save : ?git_dir:string -> ?default:string -> ?identify:bool -> string -> unit

(** Parsed OCaml compiler version - major,minor,patch,rest *)
val ocaml : (int * int * int * string) option
end
