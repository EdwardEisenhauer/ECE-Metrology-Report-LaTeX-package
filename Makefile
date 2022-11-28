TEX_SOURCES = report.tex
PACKAGE_NAME = WUST-ECE-Metrology-Report
BUILT_SOURCES = $(PACKAGE_NAME).sty

DOCKER_IMAGE = latex-builder
BUILDDIR = build

OPTIONS = -pdf -xelatex -f -interaction=nonstopmode

PDFTARGETS = $(TEX_SOURCES:.tex=.pdf)
PDFBUILDS = $(addprefix $(BUILDDIR)/, $(TEX_SOURCES:.tex=.pdf))

default: docker

.PHONY: all
all: $(PDFTARGETS) docs

.PHONY: clean
clean:
	-rm -r  $(PDFTARGETS) $(BUILDDIR) $(BUILT_SOURCES) 2>/dev/null


$(PACKAGE_NAME).sty: $(PACKAGE_NAME).dtx $(PACKAGE_NAME).ins
	mkdir -p $(BUILDDIR)
	yes | latex -output-directory=$(BUILDDIR) $(PACKAGE_NAME).ins
	yes | latex -output-directory=$(BUILDDIR) $(PACKAGE_NAME).ins
	cp $(BUILDDIR)/$@ $@

.PHONY: docs
.ONESHELL:
docs $(PACKAGE_NAME).pdf: $(PACKAGE_NAME).sty $(PACKAGE_NAME).dtx
	mkdir -p $(BUILDDIR)
	cp $(PACKAGE_NAME).dtx $(BUILDDIR)/$(PACKAGE_NAME).dtx
	cd $(BUILDDIR)
	latex $(PACKAGE_NAME).dtx
	makeindex -s gglo.ist -o $(PACKAGE_NAME).gls $(PACKAGE_NAME).glo
	makeindex -s gind.ist -o $(PACKAGE_NAME).ind $(PACKAGE_NAME).idx
	xelatex $(PACKAGE_NAME).dtx
	cp $(PACKAGE_NAME).pdf ../$(PACKAGE_NAME).pdf


$(PDFBUILDS): $(BUILDDIR)/%.pdf: %.tex
	mkdir -p $(BUILDDIR)
	echo $(PDFTARGETS)
	(latexmk $(OPTIONS) -jobname=$* -output-directory=$(BUILDDIR) $*.tex)

$(PDFTARGETS): $(BUILT_SOURCES) $(PDFBUILDS)
	cp $(BUILDDIR)/*.pdf .


.PHONY: hadolint
hadolint: Dockerfile
	docker run --rm -i hadolint/hadolint < Dockerfile

.PHONY: docker_image
docker_image: Dockerfile hadolint
	docker build \
	--tag $(DOCKER_IMAGE) \
	.

.PHONY: docker
docker: docker_image
	docker run \
		--rm \
		--volume `pwd`:/app \
		$(DOCKER_IMAGE) \
		sh -c "make -B --directory /app all"
