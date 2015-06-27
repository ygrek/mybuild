
.PHONY: build clean reinstall install uninstall

INSTALL_FILES=$(wildcard _build/*.cmx* _build/*.cmi _build/*.mli _build/*.ml _build/*.cma _build/*.cmt* _build/*.a _build/*.lib)

OCAMLBUILD=ocamlbuild -use-ocamlfind -no-links -j 0

build:
		$(OCAMLBUILD) $(BUILDFLAGS) mybuild.cma mybuild.cmxa

install: build
		ocamlfind install -patch-version "$(shell git describe --always --long)" mybuild META $(INSTALL_FILES)

uninstall:
		ocamlfind remove mybuild

reinstall:
		$(MAKE) uninstall
		$(MAKE) install

clean:
		ocamlbuild -clean