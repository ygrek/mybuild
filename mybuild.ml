open Printf
open Ocamlbuild_plugin

let bracket res destroy k =
  let x = try k res with e -> destroy res; raise e in
  destroy res;
  x

let cmd cmd = bracket (Unix.open_process_in cmd) (fun ch -> ignore & Unix.close_process_in ch) input_line

module Version = struct

let git_describe ?(dirty="+\"$(git config user.name)@$(hostname)\"") () =
  let version = cmd ("git describe --long --always --dirty=" ^ dirty ^ "") in
  let version = String.implode & List.map (function ' ' -> '.' | c -> c) & String.explode version in
  try
    match cmd "git symbolic-ref -q --short HEAD" with
    | "" | "master" -> version
    | branch -> version^"-"^branch
  with
    End_of_file -> version

let save ?(default="\"<unknown>\"") ?(identify=true) outfile =
  bracket (open_out outfile) close_out begin fun out ->
    let revision = try sprintf "%S" & git_describe ~dirty:"+M" () with _ -> default in
    let user = if identify then try cmd "git config user.name" with _ -> try Unix.getlogin () with _ -> ""  else "" in
    let host = if identify then try Unix.gethostname () with _ -> "" else "" in
    Printf.fprintf out "let id = %s\n" revision;
    Printf.fprintf out "let user = %S\n" user;
    Printf.fprintf out "let host = %S\n" host;
  end

end

module Atdgen = struct

let setup_ c =
  let ml = sprintf "_%c.ml" c in
  let prod = "%" ^ ml in
  rule ("atdgen: .atd -> " ^ ml) ~dep:"%.atd" ~prods:[prod; prod^"i"] begin fun env _ ->
    Cmd (S (
      [ P "atdgen"; T (tags_of_pathname (env prod) ++ "atdgen");
        A (sprintf "-%c" c)
      ] @
      (if c = 'j' then [A "-j-std"] else []) @ (* better use _tags? *)
      [A (env "%.atd"); ]
    ))
  end

let setup () =
  setup_ 't';
  setup_ 'b';
  setup_ 'j';
  setup_ 'v';
  pflag ["atdgen"] "atdgen" (fun s -> S [A s]);
  ()

end

module Extprot = struct

let setup () =
  rule ("extprot: proto -> ml") ~dep:"%.proto" ~prod:"%.ml" begin fun env _ ->
    let dep = env "%.proto" and prod = env "%.ml" in
    Cmd (S[ P"extprotc";
      T(tags_of_pathname prod ++ "extprot");
      A "-w"; A "200";
      A dep;
      A"-o"; A prod;
    ])
  end

end

module Ragel = struct

let setup () =
  rule ("ragel: .ml.rl -> .ml") ~dep:"%.ml.rl" ~prod:"%.ml" begin fun env _ ->
    let dep = env "%.ml.rl" and prod = env "%.ml" in
    Cmd (S[ P"ragel";
      T(tags_of_pathname prod ++ "ragel");
      A "-O";
      A "-F1";
      A dep;
      A"-o"; A prod;
    ])
  end;
  rule ("ragel: .c.rl -> .c") ~dep:"%.c.rl" ~prod:"%.c" begin fun env _ ->
    let dep = env "%.c.rl" and prod = env "%.c" in
    Cmd (S[ P"ragel";
      T(tags_of_pathname prod ++ "ragel");
      A "-C";
      A "-G2";
      A dep;
      A"-o"; A prod;
    ])
  end

end

module Cppo = struct

let setup () =
  flag ["ocaml";"pp";"pp_cppo"] & S[A"cppo"; A"-V"; A (sprintf "OCAML:%s" Sys.ocaml_version)];

end

(** common tags for ocaml compiler *)
module OCaml = struct

let setup () =
  flag ["ocaml";"compile";"native";"asm"] & S [A "-S"];
  if Sys.ocaml_version < "3.12.1" && !Options.use_ocamlfind then
    flag ["ocaml"; "link"; "toplevel"] & A"-linkpkg";
  if Sys.ocaml_version < "3.12.1" then
    pflag ["ocaml";"compile";"native"] "inline" (fun s -> S [A "-inline"; A s]);
  if Sys.ocaml_version < "4.01.0" then
    pflag ["ocaml";"compile";] "warn" (fun s -> S [A "-w"; A s]);
  if Sys.ocaml_version < "4.02.2" then
    pflag ["ocaml";"link"] "runtime_variant" (fun s -> S[A"-runtime-variant";A s]);
  ()

end

module Everything = struct

let setup () =
  OCaml.setup ();
  Atdgen.setup ();
  Extprot.setup ();
  Ragel.setup ();
  Cppo.setup ();
  ()

end

module Full = Everything
