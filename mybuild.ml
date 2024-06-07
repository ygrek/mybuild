open Printf

let bracket res destroy k =
  let x = try k res with e -> destroy res; raise e in
  destroy res;
  x

let cmd cmd = bracket (Unix.open_process_in cmd) (fun ch -> ignore @@ Unix.close_process_in ch) input_line

module Version = struct

let git_describe ?git_dir ?(dirty="+M") () =
  let git_dir = match git_dir with None -> "" | Some dir -> " --git-dir=" ^ Filename.quote dir in
  let version = cmd ("git" ^ git_dir ^ " describe --long --always --dirty=" ^ Filename.quote dirty ^ "") in
  let version = String.map (function ' ' -> '.' | c -> c) version in
  try
    match cmd "git symbolic-ref -q --short HEAD" with
    | "" | "master" -> version
    | branch -> version^"-"^branch
  with
    End_of_file -> version

let ocaml =
  let version major minor patch rest = (major, minor, patch, rest) in
  try Some (Scanf.sscanf Sys.ocaml_version "%d.%d.%d%s@\n" version) with _ -> None

let save ?git_dir ?(default="\"<unknown>\"") ?(identify=false) outfile =
  bracket (open_out outfile) close_out begin fun out ->
    let revision = try sprintf "%S" @@ git_describe ?git_dir ~dirty:"+M" () with _ -> default in
    let user = if identify then try cmd "git config user.name" with _ -> try Unix.getlogin () with _ -> ""  else "" in
    let host = if identify then try Unix.gethostname () with _ -> "" else "" in
    Printf.fprintf out "let id = Sys.opaque_identity @@ %s\n" revision;
    Printf.fprintf out "let user = Sys.opaque_identity %S\n" user;
    Printf.fprintf out "let host = Sys.opaque_identity %S\n" host;
  end

end
