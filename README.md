Mybuild
=======

Small library to generate OCaml file with the project version extracted from git + command-line utility to do the same.

How to use
----------

Add the file gen_version.ml in your project:

  let () =
    Mybuild.Version.save Sys.argv.(1)

Add the following rules in dune:

  (executable
   (name gen_version)
   (libraries mybuild)
   (modules gen_version))

  (rule
   (target version.ml)
   (deps (universe))
   (action (run ./gen_version.exe %{target})))

Then use Version.id in your program as needed.
