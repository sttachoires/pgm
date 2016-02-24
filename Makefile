# See COPYRIGHT file for copyright and license details.

include config.mk

SRC_BINS = $(wildcard bin/*.bash)
SRC_LIBS = $(wildcard lib/*.include.bash)
SRC_TEMPLATES = $(wildcard template/*/*.tpl)
SRC_CONFS = $(wildcard *.conf.sample)
SRC_DOCS = COPYRIGHT INSTALL.md CONTRIBUTORS README.md TODO CHANGELOG
SRC_MANPAGES = $(wildcard man/*.man)

BINS = $(basename $(SRC_BINS))
LIBS = $(basename $(SRC_LIBS))
CONFS = $(basename $(SRC_CONFS))
MANPAGES = $(basename $(SRC_MANPAGES))
TEMPLATES = $(basename $(SRC_TEMPLATES))
DOCS = $(SRC_DOCS)

all: options $(BINS) $(LIBS) $(TEMPLATES) $(CONFS) $(MANPAGES) $(DOCS)

options:
	@echo "${NAME} ${VERSION} install options:"
	@echo "BASH       = ${BASH}"
	@echo "USER       = ${USER}"
	@echo "PREFIX     = ${PREFIX}"
	@echo "BINDIR     = ${BINDIR}"
	@echo "LIBDIR     = ${LIBDIR}"
	@echo "SYSCONFDIR = ${SYSCONFDIR}"
	@echo "DOCDIR     = ${DOCDIR}"
	@echo "MANDIR     = ${MANDIR}"
	@echo
	@echo "SRC_BINS       = ${SRC_BINS}"
	@echo "SRC_LIBS       = ${SRC_LIBS}"
	@echo "SRC_TEMPLATES  = ${SRC_TEMPLATES}"
	@echo "SRC_CONFS      = ${SRC_CONFS}"
	@echo "SRC_MANPAGES   = ${SRC_MANPAGES}"
	@echo "SRC_DOCS       = ${SRC_DOCS}"
	@echo
	@echo "BINS       = ${BINS}"
	@echo "LIBS       = ${LIBS}"
	@echo "TEMPLATES  = ${TEMPLATES}"
	@echo "CONFS      = ${CONFS}"
	@echo "MANPAGES   = ${MANPAGES}"
	@echo "DOCS       = ${DOCS}"
	@echo

$(BINS): $(SRC_BINS)
	@echo translating paths in bash scripts: $@
	@sed -e "s%@BASH@%${BASH}%" \
		-e "s%@USER@%${USER}%" \
		-e "s%@PREFIX@%${PREFIX}%" \
		-e "s%@BINDIR@%${BINDIR}%" \
		-e "s%@LIBDIR@%${LIBDIR}%" \
		-e "s%@SYSCONFDIR@%${SYSCONFDIR}%" \
		-e "s%@DOCDIR@%${DOCDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $(addsuffix .bash,$@) > $@
	@echo done

$(LIBS): $(SRC_LIBS)
	@echo translating paths in bash scripts: $@
	@sed -e "s%@BASH@%${BASH}%" \
		-e "s%@USER@%${USER}%" \
		-e "s%@PREFIX@%${PREFIX}%" \
		-e "s%@BINDIR@%${BINDIR}%" \
		-e "s%@LIBDIR@%${LIBDIR}%" \
		-e "s%@SYSCONFDIR@%${SYSCONFDIR}%" \
		-e "s%@DOCDIR@%${DOCDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $(addsuffix .bash,$@) > $@

$(CONFS): $(SRCCONFS)
	@echo translating paths in configuration files: $@
	@sed -e "s%@BASH@%${BASH}%" \
		-e "s%@USER@%${USER}%" \
		-e "s%@PREFIX@%${PREFIX}%" \
		-e "s%@BINDIR@%${BINDIR}%" \
		-e "s%@LIBDIR@%${LIBDIR}%" \
		-e "s%@SYSCONFDIR@%${SYSCONFDIR}%" \
		-e "s%@DOCDIR@%${DOCDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $(addsuffix .sample,$@) > $@

$(MANPAGES): $(SRCMANPAGES)
	@echo translating paths in manual pages: $@
	@sed -e "s%@BASH@%${BASH}%" \
		-e "s%@USER@%${USER}%" \
		-e "s%@PREFIX@%${PREFIX}%" \
		-e "s%@BINDIR@%${BINDIR}%" \
		-e "s%@LIBDIR@%${LIBDIR}%" \
		-e "s%@SYSCONFDIR@%${SYSCONFDIR}%" \
		-e "s%@DOCDIR@%${DOCDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $(addsuffix .man,$@) > $@


clean:
	@echo cleaning
	@-rm -f $(BINS)
	@-rm -f $(LIBS)
	@-rm -f $(CONFS)
	@-rm -f $(MANPAGES)

install: all
	@echo installing executable files to ${DESTDIR}${BINDIR}
	@mkdir -p ${DESTDIR}${BINDIR}
	@cp -f $(BINS) ${DESTDIR}${BINDIR}
	@chmod 755 $(addprefix ${DESTDIR}${BINDIR}/,$(BINS))
	@echo installing helpers to ${DESTDIR}${LIBDIR}/${NAME}
	@mkdir -p ${DESTDIR}${LIBDIR}/${NAME}
	@cp -f $(LIBS) ${DESTDIR}${LIBDIR}/${NAME}
	@chmod 755 $(addprefix ${DESTDIR}${LIBDIR}/${NAME}/,$(LIBS))
	@echo installing configuration to ${DESTDIR}${SYSCONFDIR}
	@mkdir -p ${DESTDIR}${SYSCONFDIR}
	@-cp -i $(CONFS) ${DESTDIR}${SYSCONFDIR} < /dev/null >/dev/null 2>&1
	@echo installing docs to ${DESTDIR}${DOCDIR}
	@mkdir -p ${DESTDIR}${DOCDIR}
	@cp -f $(CONFS) $(DOCS) ${DESTDIR}${DOCDIR}
	@echo installing man pages to ${DESTDIR}${MANDIR}
	@mkdir -p ${DESTDIR}${MANDIR}/man1
	@cp -f $(MANPAGES) ${DESTDIR}${MANDIR}/man1

uninstall:
	@echo removing executable files from ${DESTDIR}${BINDIR}
	@rm -f $(addprefix ${DESTDIR}${BINDIR}/,$(BINS))
	@rm -f ${DESTDIR}${BINDIR}/pitr_mgr
	@echo removing helpers from ${DESTDIR}${LIBDIR}/${NAME}
	@rm -f $(addprefix ${DESTDIR}${LIBDIR}/${NAME}/,$(LIBS))
	@-rmdir ${DESTDIR}${LIBDIR}/${NAME}
	@echo removing docs from ${DESTDIR}${DOCDIR}
	@rm -f $(addprefix ${DESTDIR}${DOCDIR}/,$(CONFS))
	@rm -f $(addprefix ${DESTDIR}${DOCDIR}/,$(DOCS))
	@-rmdir ${DESTDIR}${DOCDIR}
	@echo removing man pages from ${DESTDIR}${MANDIR}
	@rm -f $(addprefix ${DESTDIR}${MANDIR}/man1/,$(MANPAGES))

.PHONY: all options clean install uninstall
