# See COPYRIGHT file for copyright and license details.

include config.mk

SRC_BINS = $(wildcard bin/*.bash)
SRC_LIBS = $(wildcard lib/*.include.bash)
SRC_TEMPLATES = $(wildcard template/*/*.tpl.orig)
SRC_CONFS = $(wildcard *.conf.sample)
SRC_DOCS = COPYRIGHT INSTALL.md CONTRIBUTORS README.md TODO CHANGELOG
SRC_MANPAGES = $(wildcard man/*.man)

BINS = $(basename $(SRC_BINS))
LIBS = $(basename $(SRC_LIBS))
CONFS = $(basename $(SRC_CONFS))
MANPAGES = $(basename $(SRC_MANPAGES))
TEMPLATES = $(basename $(SRC_TEMPLATES))
DOCS = $(SRC_DOCS)

DEST_BINS = $(BINS:bin/%=${BINDIR}/%)
DEST_LIBS = $(LIBS:lib/%=${LIBDIR}/%)
DEST_CONFS = $(CONFS:%=${CONFDIR}/%)
DEST_MANPAGES = $(MANPAGES:man/%=${MANDIR}/man1/%)
DEST_TEMPLATES = $(TEMPLATES:template/%=${TEMPLATEDIR}/%)
DEST_DOCS = $(DOCS:%=${DOCDIR}/%)

all: options $(BINS) $(LIBS) $(CONFS) $(MANPAGES) $(TEMPLATES) $(DOCS)

options:
	@echo "${NAME} ${VERSION} install options:"
	@echo "BASH            = ${BASH}"
	@echo "USER            = ${USER}"
	@echo "USERNUM         = ${USERNUM}"
	@echo "GROUP           = ${GROUP}"
	@echo "GROUPNUM        = ${GROUPNUM}"
	@echo "PREFIX          = ${PREFIX}"
	@echo "BINDIR          = ${BINDIR}"
	@echo "LIBDIR          = ${LIBDIR}"
	@echo "TEMPLATESDIR    = ${TEMPLATESDIR}"
	@echo "CONFDIR         = ${CONFDIR}"
	@echo "DOCDIR          = ${DOCDIR}"
	@echo "MANDIR          = ${MANDIR}"
	@echo
	@echo "SRC_BINS        = ${SRC_BINS}"
	@echo "SRC_LIBS        = ${SRC_LIBS}"
	@echo "SRC_TEMPLATES   = ${SRC_TEMPLATES}"
	@echo "SRC_CONFS       = ${SRC_CONFS}"
	@echo "SRC_DOCS        = ${SRC_DOCS}"
	@echo "SRC_MANPAGES    = ${SRC_MANPAGES}"
	@echo
	@echo "BINS            = ${BINS}"
	@echo "LIBS            = ${LIBS}"
	@echo "TEMPLATES       = ${TEMPLATES}"
	@echo "CONFS           = ${CONFS}"
	@echo "DOCS            = ${DOCS}"
	@echo "MANPAGES        = ${MANPAGES}"
	@echo
	@echo "DEST_BINS       = ${DEST_BINS}"
	@echo "DEST_LIBS       = ${DEST_LIBS}"
	@echo "DEST_TEMPLATES  = ${DEST_TEMPLATES}"
	@echo "DEST_CONFS      = ${DEST_CONFS}"
	@echo "DEST_DOCS       = ${DEST_DOCS}"
	@echo "DEST_MANPAGES   = ${DEST_MANPAGES}"
	@echo

$(BINS): $(SRC_BINS)
	@echo translating paths in bash scripts: $@
	@sed -e "s%@BASH@%${BASH}%" \
		-e "s%@USER@%${USER}%" \
		-e "s%@VERSION@%${VERSION}%" \
		-e "s%@PREFIX@%${PREFIX}%" \
		-e "s%@BINDIR@%${BINDIR}%" \
		-e "s%@LIBDIR@%${LIBDIR}%" \
		-e "s%@CONFDIR@%${CONFDIR}%" \
		-e "s%@DOCDIR@%${DOCDIR}%" \
		-e "s%@USERNUM@%${USERNUM}%" \
		-e "s%@GROUP@%${GROUP}%" \
		-e "s%@GROUPNUM@%${GROUPNUM}%" \
		-e "s%@TEMPLATESDIR@%${TEMPLATESDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $(addsuffix .bash,$@) > $@
	@echo done

$(LIBS): $(SRC_LIBS)
	@echo translating paths in bash scripts: $@
	@sed -e "s%@BASH@%${BASH}%" \
		-e "s%@USER@%${USER}%" \
		-e "s%@VERSION@%${VERSION}%" \
		-e "s%@PREFIX@%${PREFIX}%" \
		-e "s%@BINDIR@%${BINDIR}%" \
		-e "s%@LIBDIR@%${LIBDIR}%" \
		-e "s%@CONFDIR@%${CONFDIR}%" \
		-e "s%@DOCDIR@%${DOCDIR}%" \
		-e "s%@USERNUM@%${USERNUM}%" \
		-e "s%@GROUP@%${GROUP}%" \
		-e "s%@GROUPNUM@%${GROUPNUM}%" \
		-e "s%@TEMPLATESDIR@%${TEMPLATESDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $(addsuffix .bash,$@) > $@

$(TEMPLATES): $(SRC_TEMPLATE)
	@echo translating paths in bash scripts: $@
	@sed -e "s%@BASH@%${BASH}%" \
		-e "s%@USER@%${USER}%" \
		-e "s%@VERSION@%${VERSION}%" \
		-e "s%@PREFIX@%${PREFIX}%" \
		-e "s%@BINDIR@%${BINDIR}%" \
		-e "s%@LIBDIR@%${LIBDIR}%" \
		-e "s%@CONFDIR@%${CONFDIR}%" \
		-e "s%@DOCDIR@%${DOCDIR}%" \
		-e "s%@USERNUM@%${USERNUM}%" \
		-e "s%@GROUP@%${GROUP}%" \
		-e "s%@GROUPNUM@%${GROUPNUM}%" \
		-e "s%@TEMPLATESDIR@%${TEMPLATESDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $(addsuffix .orig,$@) > $@

$(CONFS): $(SRC_CONFS)
	@echo translating paths in configuration files: $@
	@sed -e "s%@BASH@%${BASH}%" \
		-e "s%@USER@%${USER}%" \
		-e "s%@VERSION@%${VERSION}%" \
		-e "s%@PREFIX@%${PREFIX}%" \
		-e "s%@BINDIR@%${BINDIR}%" \
		-e "s%@LIBDIR@%${LIBDIR}%" \
		-e "s%@CONFDIR@%${CONFDIR}%" \
		-e "s%@DOCDIR@%${DOCDIR}%" \
		-e "s%@USERNUM@%${USERNUM}%" \
		-e "s%@GROUP@%${GROUP}%" \
		-e "s%@GROUPNUM@%${GROUPNUM}%" \
		-e "s%@TEMPLATESDIR@%${TEMPLATESDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $(addsuffix .sample,$@) > $@

$(MANPAGES): $(SRCMANPAGES)
	@echo translating paths in manual pages: $@
	@sed -e "s%@BASH@%${BASH}%" \
		-e "s%@USER@%${USER}%" \
		-e "s%@VERSION@%${VERSION}%" \
		-e "s%@PREFIX@%${PREFIX}%" \
		-e "s%@BINDIR@%${BINDIR}%" \
		-e "s%@LIBDIR@%${LIBDIR}%" \
		-e "s%@CONFDIR@%${CONFDIR}%" \
		-e "s%@DOCDIR@%${DOCDIR}%" \
		-e "s%@USERNUM@%${USERNUM}%" \
		-e "s%@GROUP@%${GROUP}%" \
		-e "s%@GROUPNUM@%${GROUPNUM}%" \
		-e "s%@TEMPLATESDIR@%${TEMPLATESDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $(addsuffix .man,$@) > $@


clean:
	@echo cleaning
	@-rm -f $(BINS)
	@-rm -f $(LIBS)
	@-rm -f $(TEMPLATE)
	@-rm -f $(CONFS)
	@-rm -f $(MANPAGES)

user :
	@echo adding ${GROUP} group and ${USER} user
	@groupadd --force --gid=${GROUPNUM} --system ${GROUP}
	@useradd --comment="DBA user for PGM scripts" --gid=${GROUPNUM} --no-user-group --system --shell=${BASH} --uid=${USERNUM} --create-home ${USER}

$(DEST_BINS) : $(SRC_BINS)
	@echo installing executable files to ${BINDIR}
	@mkdir --parents ${BINDIR}
	@cp --force --recursive $(BINS) ${BINDIR}
	@chmod u=rx,go= $(DEST_BINS)
	@chown --recursive ${USER}:${GROUP} ${BINDIR}

$(DEST_LIBS) :$(SRC_LIBS)
	@echo installing library files to ${LIBDIR}
	@mkdir --parents ${LIBDIR}
	@cp --force --recursive $(LIBS) ${LIBDIR}
	@chmod u=r,go= $(DEST_LIBS)
	@chown --recursive ${USER}:${GROUP} ${LIBDIR}

$(DEST_TEMPLATES): $(SRC_TEMPLATES)
	@echo installing template files to ${TEMPLATEDIR}
	@mkdir --parents ${TEMPLATEDIR}
	@tar cfz $(DEST_TEMPLATES) ${TEMPLATEDIR}/save.$(shell date +'%Y.%m.%d_%H.%M.%S')
	@cp --force --recursive $(TEMPLATES) ${TEMPLATEDIR}
	@chmod u=r,go= $(DEST_TEMPLATES)
	@chown --recursive ${USER}:${GROUP} ${TEMPLATEDIR}

$(DEST_CONFS): $(SRC_CONFS)
	@echo installing configuration files to ${CONFDIR}
	@mkdir --parents ${CONFDIR}
	@tar cfz $(DEST_CONFS) ${DESTDIR}/save.$(shell date +'%Y.%m.%d_%H.%M.%S')
	@cp --force --recursive $(CONFS) ${CONFDIR}
	@chmod u=rw,go= $(DEST_CONF)
	@chown --recursive ${USER}:${GROUP} ${CONFDIR}

$(DEST_DOCS): $(SRC_DOCS)
	@echo installing documentation to ${DOCDIR}
	@mkdir --parents ${DOCDIR}
	@cp --force --recursive $(DOCS) ${DOCDIR}
	@chmod a=r $(DEST_DOC)
	@chown --recursive ${USER}:${GROUP} ${DOCDIR}

$(DEST_MANPAGES): $(SRC_MANPAGES)
	@echo installing manual files to ${MANDIR}
	@mkdir --parents ${MANDIR}
	@cp --force --recursive $(MANPAGES) ${MANDIR}
	@chmod a=r $(DEST_MANPAGES})
	@chown --recursive ${USER}:${GROUP} ${MANDIR}


install: | all user $(DEST_BINS) $(DEST_LIBS) $(DEST_TEMPLATES) $(DEST_CONFS) $(DEST_DOCS) $(DEST_MANPAGES)
	@chmod u=rwx,ro= ${PREFIX}
	@chown --recursive ${USER}:${GROUP} ${PREFIX}

uninstall:
	@echo removing all files from ${PREFIX}
	@rm -f $(DEST_ALL)

.PHONY: all options clean install uninstall
