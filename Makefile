LATEX ?= pdflatex
WHICH = command -v

LATEXSOURCES = \
	docs/*.tex \
	lkmm-README.tex \
	rcu/*.tex \
	qqz.sty \
	pfbook.cls \
	pfhyphex.tex \
	ushyphex.tex

LATEXGENERATED = autodate.tex qqz.tex

LATEXPAND := $(shell $(WHICH) latexpand 2>/dev/null)

ifdef LATEXPAND
  LATEXPAND_OPTS = --empty-comments
  # Note: Option --non-global to latexpand is added locally for testing
  # before possible upstreaming
  LATEXPAND_NON_GLOBAL := $(shell latexpand --help | grep -c -e "--non-global")
  ifneq ($(LATEXPAND_NON_GLOBAL),0)
    LATEXPAND_OPTS += --non-global
  endif
endif

.PHONY: all clean

all: lkmm-docs.pdf

autodate.tex: $(LATEXSOURCES)
	sh utilities/autodate.sh

lkmm-docs_flat.tex: autodate.tex
	echo > qqz.tex
	latexpand $(LATEXPAND_OPTS) lkmm-docs.tex 1> $@ 2> /dev/null

qqz.tex: lkmm-docs_flat.tex
	sh utilities/extractqqz.sh < $< | perl utilities/qqzreorder.pl > $@

lkmm-docs.pdf: qqz.tex
	latexmk -pdf lkmm-docs.tex

clean:
	latexmk -C
	rm -f $(LATEXGENERATED)
