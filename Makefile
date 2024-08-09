LATEX ?= pdflatex
WHICH = command -v
SED ?= sed

LATEXSOURCES = \
	lkmm-docs.tex \
	docs/*.tex \
	lkmm-README.tex \
	rcu/*.tex \
	rcu/*/*.tex \
	qqz.sty \
	pfbook.cls \
	pfhyphex.tex \
	ushyphex.tex

LATEXGENERATED = autodate.tex qqz.tex lkmm-docs_flat.tex

SVGSOURCES_ALL := $(wildcard rcu/*/*.svg)
SVG_EMERGENCY := $(wildcard rcu/*/*.svg*.svg)
SVGSOURCES := $(filter-out $(SVG_EMERGENCY) $(SVG_GENERATED),$(SVGSOURCES_ALL)) $(SVG_GENERATED)
PDFTARGETS_OF_SVG := $(SVGSOURCES:%.svg=%.pdf)

INKSCAPE := $(shell $(WHICH) inkscape 2>/dev/null)
ifdef INKSCAPE
  INKSCAPE_ONE := $(shell inkscape --version 2>/dev/null | grep -c "Inkscape 1")
endif
# rsvg-convert is preferred to inkscape in SVG --> PDF conversion
RSVG_CONVERT := $(shell $(WHICH) rsvg-convert 2>/dev/null)
ifdef RSVG_CONVERT
  RSVG_CONVERT_VER := $(shell rsvg-convert --version | $(SED) -e 's/rsvg-convert version //')
  RSVG_CONVERT_VER_MINOR := $(shell echo $(RSVG_CONVERT_VER) | $(SED) -E -e 's/^([0-9]+\.[0-9]+).*/\1/')
  RSVG_CONVERT_GOOD_VER ?= 2.57
  RSVG_CONVERT_PDFFMT_VER := 2.57
  RSVG_CONVERT_ACCEPTABLE_VER := 2.52
  RSVG_CONVERT_GOOD := $(shell echo $(RSVG_CONVERT_VER_MINOR) $(RSVG_CONVERT_GOOD_VER) | awk '{if ($$1 >= $$2) print 1;}')
  RSVG_CONVERT_ACCEPTABLE := $(shell echo $(RSVG_CONVERT_VER_MINOR) $(RSVG_CONVERT_ACCEPTABLE_VER) | awk '{if ($$1 == $$2) print 1;}')
  ifeq ($(RSVG_CONVERT_ACCEPTABLE),1)
    RSVG_CONVERT_GOOD := 1
  endif
  ifndef INKSCAPE
    RSVG_CONVERT_GOOD := 1
  endif
  RSVG_CONVERT_PDFFMT := $(shell echo $(RSVG_CONVERT_VER_MINOR) $(RSVG_CONVERT_PDFFMT_VER) | awk '{if ($$1 >= $$2) print 1;}')
  ifeq ($(RSVG_CONVERT_GOOD),1)
    SVG_PDF_CONVERTER = (rsvg-convert v$(RSVG_CONVERT_VER))
  else
    SVG_PDF_CONVERTER = (inkscape)
  endif
  ifeq ($(RSVG_CONVERT_PDFFMT),1)
    RSVG_FMT_OPT := --format=pdf1.5
  else
    RSVG_FMT_OPT := --format=pdf
  endif
else
  SVG_PDF_CONVERTER = (inkscape)
endif

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

.PHONY: all clean cleanfigs neatfreak

all: lkmm-docs.pdf

autodate.tex: $(LATEXSOURCES)
	sh utilities/autodate.sh

lkmm-docs_flat.tex: autodate.tex
	echo > qqz.tex
	latexpand $(LATEXPAND_OPTS) lkmm-docs.tex 1> $@ 2> /dev/null

qqz.tex: lkmm-docs_flat.tex
	sh utilities/extractqqz.sh < $< | perl utilities/qqzreorder.pl > $@

lkmm-docs.pdf: qqz.tex $(PDFTARGETS_OF_SVG)
	latexmk -pdf lkmm-docs.tex

$(PDFTARGETS_OF_SVG): %.pdf: %.svg
	@echo "$< --> $(suffix $@) $(SVG_PDF_CONVERTER)"
ifneq ($(RSVG_CONVERT_GOOD),1)
  ifndef INKSCAPE
	$(error $< --> $@ inkscape nor rsvg-convert not found. Please install either one)
  endif
endif
ifeq ($(RECOMMEND_FREEFONT),1)
	$(info Nice-to-have font family 'FreeMono' not found. See #9 in FAQ-BUILD.txt)
endif
ifeq ($(RECOMMEND_DEJAVUSANS),1)
	$(info Nice-to-have font family 'DejaVu Sans' not found. See #9 in FAQ-BUILD.txt)
endif
ifeq ($(RECOMMEND_DEJAVUMONO),1)
	$(info Nice-to-have font family 'DejaVu Sans Mono' not found. See #9 in FAQ-BUILD.txt)
endif
ifeq ($(RECOMMEND_LIBERATIONSANS),1)
	$(info Nice-to-have font family 'Liberation Sans' not found. See #9 in FAQ-BUILD.txt)
endif
ifeq ($(RECOMMEND_LIBERATIONMONO),1)
	$(info Nice-to-have font family 'Liberation Mono' not found. See #9 in FAQ-BUILD.txt)
endif

ifeq ($(RSVG_CONVERT_GOOD),1)
	@cat $< | rsvg-convert $(RSVG_FMT_OPT) > $@
else
  ifeq ($(INKSCAPE_ONE),0)
	@inkscape --export-pdf=$@ $< > /dev/null 2>&1
  else
	@$(ISOLATE_INKSCAPE) inkscape -o $@ $< > /dev/null 2>&1
  endif
endif

cleanfigs:
	rm -f $(PDFTARGETS_OF_SVG)

clean:
	latexmk -C
	rm -f $(LATEXGENERATED)

neatfreak: cleanfigs clean
