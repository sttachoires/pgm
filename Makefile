# See COPYRIGHT file for copyright and license details.

include config.mk

SRC_BINS:=$(wildcard bin/*.bash)
SRC_LIBS:=$(wildcard lib/*.include.bash)
SRC_TPLS:=$(wildcard tplptrn/*/*.tpl.ptrn)
SRC_CONFS:=$(wildcard *.conf.sample)
SRC_DOCS:=COPYRIGHT INSTALL.md CONTRIBUTORS README.md TODO CHANGELOG
SRC_MANPAGES:=$(wildcard man/*.man)

BINS:=$(basename $(SRC_BINS))
LIBS:=$(basename $(SRC_LIBS))
CONFS:=$(basename $(SRC_CONFS))
MANPAGES:=$(basename $(SRC_MANPAGES))
TPLS:=$(basename $(SRC_TPLS))
DOCS:=$(SRC_DOCS)
BASH_PROFILE:="$(shell echo "/home/${USER}")/.bash_profile"
DEST_BINS:=$(BINS:bin/%=${BINDIR}/%)
DEST_LIBS:=$(LIBS:lib/%=${LIBDIR}/%)
DEST_CONFS:=$(CONFS:%=${CONFDIR}/%)
DEST_MANPAGES:=$(MANPAGES:man/%=${MANDIR}/man1/%)
DEST_TPLS:=$(TPLS:tplptrn/%=${TPLDIR}/%)
DEST_DOCS:=$(DOCS:%=${DOCDIR}/%)

NOGROUP=nogroup
NOUSER=nouser
GREPGROUP:=$(shell grep --only-matching "^${GROUP}:x" /etc/group)
GROUPEXISTS:=$(patsubst %:x,%,$(GREPGROUP))
GROUPCREATE:=$(if $(GROUPEXISTS),$(NOGROUP),$(GROUP))
GREPUSER:=$(shell grep --only-matching "^$(USER):x" /etc/passwd)
USEREXISTS:=$(patsubst %:x,%,$(GREPUSER))
USERCREATE:=$(if $(USEREXISTS),$(NOUSER),$(USER))

SAVE_TPLS=save_tpls
NO_SAVE_TPLS=no_save_tpls
TPLS_TO_SAVE:=$(wildcard $(TPLDIR)/*/*.tpl)
BACKUP_OLD_TPLS:=$(filter-out %/save.%, $(if $(TPLS_TO_SAVE),$(SAVE_TPLS),$(NO_SAVE_TPLS)))
SAVE_CONFS=save_confs
NO_SAVE_CONFS=no_save_confs
CONFS_TO_SAVE:=$(filter-out $(CONFDIR)/save.%, $(wildcard $(CONFDIR)/*))
BACKUP_OLD_CONFS:=$(if $(CONFS_TO_SAVE),$(SAVE_CONFS),$(NO_SAVE_CONFS))

all: options $(BINS) $(LIBS) $(CONFS) $(MANPAGES) $(TPLS) $(DOCS)
	@echo

install: | all ${GROUPCREATE} $(USERCREATE) $(DEST_BINS) $(DEST_LIBS) $(BACKUP_OLD_TPLS) $(DEST_TPLS) $(BACKUP_OLD_CONFS) $(DEST_CONFS) $(DEST_DOCS) $(DEST_MANPAGES)
	chmod u=rwx,go= ${PREFIX}
	chown --recursive ${USER}:${GROUP} ${PREFIX}
	@echo

uninstall:
	@echo removing all files from ${PREFIX}
	@rm -f $(DEST_BINS)
	@rm -f $(DEST_LIBS)
	@rm -f $(DEST_TPLS)
	@rm -f $(DEST_CONFS)
	@rm -f $(DEST_DOCS)
	@rm -f $(DEST_MANPAGES)
	@echo

cleansave:
	@echo removing all backup configutations and templates and dirs from ${PREFIX}
	@rm -f $(wildcard $(TPLDIR)/save.*)
	@rm -f $(wildcard $(CONFIR)/save.*)
	@echo

clean:
	@echo cleaning
	@rm -f $(BINS)
	@rm -f $(LIBS)
	@rm -f $(TPLS)
	@rm -f $(CONFS)
	@rm -f $(MANPAGES)
	@echo

options:
	@echo
	@echo "######"
	@echo "${NAME} ${VERSION} install options:"
	@echo "######"
	@echo "BASH             =${BASH}"
	@echo "USER             =${USER}"
	@echo "USERNUM          =${USERNUM}"
	@echo "GROUP            =${GROUP}"
	@echo "GROUPNUM         =${GROUPNUM}"
	@echo "PREFIX           =${PREFIX}"
	@echo "BINDIR           =${BINDIR}"
	@echo "LIBDIR           =${LIBDIR}"
	@echo "TPLDIR           =${TPLDIR}"
	@echo "CONFDIR          =${CONFDIR}"
	@echo "DOCDIR           =${DOCDIR}"
	@echo "MANDIR           =${MANDIR}"
	@echo "BASH_PROFILE     =${BASH_PROFILE}"
	@echo
	@echo "SRC_BINS         =${SRC_BINS}"
	@echo "SRC_LIBS         =${SRC_LIBS}"
	@echo "SRC_TPLS         =${SRC_TPLS}"
	@echo "SRC_CONFS        =${SRC_CONFS}"
	@echo "SRC_DOCS         =${SRC_DOCS}"
	@echo "SRC_MANPAGES     =${SRC_MANPAGES}"
	@echo
	@echo "BINS             =${BINS}"
	@echo "LIBS             =${LIBS}"
	@echo "TPLS             =${TPLS}"
	@echo "CONFS            =${CONFS}"
	@echo "DOCS             =${DOCS}"
	@echo "MANPAGES         =${MANPAGES}"
	@echo
	@echo "DEST_BINS        =${DEST_BINS}"
	@echo "DEST_LIBS        =${DEST_LIBS}"
	@echo "DEST_TPLS        =${DEST_TPLS}"
	@echo "DEST_CONFS       =${DEST_CONFS}"
	@echo "DEST_DOCS        =${DEST_DOCS}"
	@echo "DEST_MANPAGES    =${DEST_MANPAGES}"
	@echo
	@echo "TPLS_TO_SAVE     =${TPLS_TO_SAVE}"
	@echo "BACKUP_OLD_TPLS  =${BACKUP_OLD_TPLS}"
	@echo "CONFS_TO_SAVE    =${CONFS_TO_SAVE}"
	@echo "BACKUP_OLD_CONFS =${BACKUP_OLD_CONFS}"
	@echo "######"
	@echo

bin/%:bin/%.bash
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
		-e "s%@TPLSDIR@%${TPLSDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $< > $@
	@echo

lib/%:lib/%.bash
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
		-e "s%@TPLSDIR@%${TPLSDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $< > $@
	@echo

$(TPLS): $(SRC_TPL) 
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
		-e "s%@TPLSDIR@%${TPLSDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $(addsuffix .ptrn,$@) > $@
	@echo

$(CONFS): $(SRC_CONFS)
	@echo translating paths in configuration files: $@
	sed -e "s%@BASH@%${BASH}%" \
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
		-e "s%@TPLSDIR@%${TPLSDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $(addsuffix .sample,$@) > $@
	@echo

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
		-e "s%@TPLSDIR@%${TPLSDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $(addsuffix .man,$@) > $@
	@echo

$(USER) :
	@echo adding ${USER} user
	adduser --gid=${GROUPNUM} --system --shell=${BASH} --uid=${USERNUM} --home=${PREFIX} ${USER}
	touch ${BASH_PROFILE}
	cp -f ${BASH_PROFILE} ${BASH_PROFILE}.save
	echo "export PATH=\"${BINDIR}:${PATH}\"" > ${BASH_PROFILE}
	echo "alias ll='ls -laF $*'" >> ${BASH_PROFILE}
	echo "alias pgmsql='pgm_psql $*'" >> ${BASH_PROFILE}
	chown ${USER}:${GROUP} ${BASH_PROFILE}
	@echo

$(NOUSER) :
	@echo ${USER} already exists, you should add 'export PATH=\"${BINDIR}:${PATH}\"' to his .bash_profile
	@echo

$(GROUP) :
	@echo adding ${GROUP} group
	@addgroup --gid=${GROUPNUM} --system ${GROUP}
	@echo

$(NOGROUP) :
	@echo ${GROUP} already exists
	@echo

$(DEST_BINS) : $(SRC_BINS)
	@echo installing executable files to ${BINDIR}
	@mkdir --parents ${BINDIR}
	@cp --force --recursive $(BINS) ${BINDIR}
	@chmod u=rx,go= $(DEST_BINS)
	@chown --recursive ${USER}:${GROUP} ${BINDIR}
	@echo

$(DEST_LIBS) :$(SRC_LIBS)
	@echo installing library files to ${LIBDIR}
	@mkdir --parents ${LIBDIR}
	@cp --force --recursive $(LIBS) ${LIBDIR}
	@chmod u=r,go= $(DEST_LIBS)
	@chown --recursive ${USER}:${GROUP} ${LIBDIR}
	@echo

$(NO_SAVE_TPLS) :
	@echo no tplptrns to save
	@echo

$(SAVE_TPLS) :
	@echo saving old templates $(TPLS_TO_SAVE)
	@tar --preserve-permissions --exclude $(TPLDIR)/save.* --create --gzip --file $(TPLDIR)/save.$(shell date +'%Y.%m.%d_%H.%M.%S') $(TPLS_TO_SAVE)
	@echo

$(TPLDIR)/%:$(TPLS:template/%=%)
	@echo installing tplptrn files $< to ${TPLDIR}
	@mkdir --parents $(dir $@)
	@cp --recursive $< $@
	@chmod  u=r,go= $@
	@chown  ${USER}:${GROUP} $@
	@echo

$(NO_SAVE_CONFS) :
	@echo no conf to save
	@echo

$(SAVE_CONFS) :
	@echo saving old configuration $(TPLS_TO_SAVE)
	@tar --preserve-permissions --exclude $(CONFDIR)/save.* --create --gzip --file $(CONFDIR)/save.$(shell date +'%Y.%m.%d_%H.%M.%S') "$(CONFDIR)"
	@echo

$(DEST_CONFS): | $(BACKUP_OLD_CONF) $(SRC_CONFS)
	@echo installing configuration files to ${CONFDIR}
	@mkdir --parents ${CONFDIR}
	@cp --force --recursive $(CONFS) $(CONFDIR)
	@chmod --recursive u=rw,go= $(CONFDIR)
	@chown --recursive ${USER}:${GROUP} ${CONFDIR}
	@echo

$(DEST_DOCS): $(SRC_DOCS)
	@echo installing documentation to ${DOCDIR}
	@mkdir --parents ${DOCDIR}
	@cp --force --recursive $(DOCS) $(DOCDIR)
	@chmod a=r $(DEST_DOCS)
	@chown --recursive ${USER}:${GROUP} ${DOCDIR}
	@echo

$(DEST_MANPAGES): $(SRC_MANPAGES)
	@echo installing manual files to ${MANDIR}
	@mkdir --parents $(MANDIR)/man1
	@cp --force --recursive $(MANPAGES) $(MANDIR)/man1
	@chmod a=r $(DEST_MANPAGES)
	@chown --recursive $(USER):${GROUP} $(MANDIR)/man1
	@echo

.PHONY: all options clean install uninstall nogroup nouser nosavetpls nosaveconfs
