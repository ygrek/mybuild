open Arg

let message = "small utility to write OCaml file with version information extracted from VCS"

let () =
  let file = ref None in
  let identify = ref false in
  let git_dir = ref None in
  let default = ref None in
  let args = align [
    "-write", String (fun s -> file := Some s), "<file> file to write version code to (default: nothing is written)";
    "-identify", Set identify, "<bool> whether to write user id and host (default: false)";
    "-git-dir", String (fun s -> git_dir := Some s), "<dir> specify git-dir to use (default: none)";
    "-default", String (fun s -> default := Some s), "<version> version string to use if VCS information is absent (default: empty)";
  ]
  in
  parse args failwith message;
  match !file with
  | None -> Arg.usage args message 
  | Some file -> Mybuild.Version.save ~identify:!identify ?git_dir:!git_dir ?default:!default file
