LATEX ?= pdflatex
WHICH = command -v

LATEXSOURCES = \
	lkmm-docs-*.tex \
	lkmm-README.tex \
	rcu/*.tex \
	qqz.sty \
	pfbook.cls \
	pfhyphex.tex \
	ushyphex.tex

LATEXGENERATED = autodate.tex qqz.tex

.PHONY: all

all: lkmm-docs-eb.pdf

autodate.tex: $(LATEXSOURCES)
	sh utilities/autodate.sh

lkmm-docs_flat.tex: autodate.tex
	echo > qqz.tex
	latexpand --empty-comments lkmm-docs-eb.tex 1> $@ 2> /dev/null

qqz.tex: lkmm-docs_flat.tex
	sh utilities/extractqqz.sh < $< | perl utilities/qqzreorder.pl > $@

lkmm-docs-eb.pdf: qqz.tex
	latexmk -pdf lkmm-docs-eb.tex

