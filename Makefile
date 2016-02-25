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
TPLS:=$(basename $(SRC_TPLS:tplptrn/%=templates/%))
DOCS:=$(SRC_DOCS)

DEST_BINS:=$(BINS:bin/%=${BINDIR}/%)
DEST_LIBS:=$(LIBS:lib/%=${LIBDIR}/%)
DEST_CONFS:=$(CONFS:%=${CONFDIR}/%)
DEST_MANPAGES:=$(MANPAGES:man/%=${MANDIR}/man1/%)
DEST_TPLS:=$(TPLS:templates/%=${TPLDIR}/%)
DEST_DOCS:=$(DOCS:%=${DOCDIR}/%)

NOGROUP=nogroup
NOUSER=nouser
GREPGROUP:=$(shell grep --only-matching "^${GROUP}:x" /etc/group)
GROUPEXISTS:=$(patsubst %:x,%,$(GREPGROUP))
GROUPCREATE:=$(if $(GROUPEXISTS),$(NOGROUP),$(GROUP))
GREPUSER:=$(shell grep --only-matching "^$(USER):x" /etc/passwd)
USEREXISTS:=$(patsubst %:x,%,$(GREPUSER))
USERCREATE:=$(if $(USEREXISTS),$(NOUSER),$(USER))

SAVE_TPL=save_tplptrns
NO_SAVE_TPLS=no_save_tplptrns
TPL_TO_SAVE:=$(wildcard $(TPLDIR)/*.tpl)
BACKUP_OLD_TPL:=$(if $(TPLS_TO_SAVE),$(SAVE_TPLS), $(NO_SAVE_TPLS))
SAVE_CONF=save_conf
NO_SAVE_CONF=no_save_conf
CONF_TO_SAVE:=$(wildcard $(CONFDIR)/*)
BACKUP_OLD_CONF:=$(if $(CONF_TO_SAVE);$(SAVE_CONF),$(NO_SAVE_CONF))

all: options $(BINS) $(LIBS) $(CONFS) $(MANPAGES) $(TPLS) $(DOCS)
	@echo "GROUPCREATE=${GROUPCREATE}"
	@echo "USERCREATE=${USERCREATE}"
	@echo "GROUPEXISTS=${GROUPEXISTS}"
	@echo "USEREXISTS=${USEREXISTS}"

install: all ${GROUPCREATE} $(USERCREATE) $(DEST_BINS) $(DEST_LIBS) $(DEST_TPLS) $(DEST_CONFS) $(DEST_DOCS) $(DEST_MANPAGES)
	@chmod u=rwx,ro= ${PREFIX}
	@chown --recursive ${USER}:${GROUP} ${PREFIX}

uninstall:
	@echo removing all files from ${PREFIX}
	@rm -f $(DEST_ALL)

clean:
	@echo cleaning
	rm -f $(BINS)
	rm -f $(LIBS)
	rm -f $(TPLS)
	rm -f $(CONFS)
	rm -f $(MANPAGES)

options:
	@echo "${NAME} ${VERSION} install options:"
	@echo "BASH           :=${BASH}"
	@echo "USER           :=${USER}"
	@echo "USERNUM        :=${USERNUM}"
	@echo "GROUP          :=${GROUP}"
	@echo "GROUPNUM       :=${GROUPNUM}"
	@echo "PREFIX         :=${PREFIX}"
	@echo "BINDIR         :=${BINDIR}"
	@echo "LIBDIR         :=${LIBDIR}"
	@echo "TPLSDIR   :=${TPLSDIR}"
	@echo "CONFDIR        :=${CONFDIR}"
	@echo "DOCDIR         :=${DOCDIR}"
	@echo "MANDIR         :=${MANDIR}"
	@echo
	@echo "SRC_BINS       :=${SRC_BINS}"
	@echo "SRC_LIBS       :=${SRC_LIBS}"
	@echo "SRC_TPLS  :=${SRC_TPLS}"
	@echo "SRC_CONFS      :=${SRC_CONFS}"
	@echo "SRC_DOCS       :=${SRC_DOCS}"
	@echo "SRC_MANPAGES   :=${SRC_MANPAGES}"
	@echo
	@echo "BINS           :=${BINS}"
	@echo "LIBS           :=${LIBS}"
	@echo "TPLS      :=${TPLS}"
	@echo "CONFS          :=${CONFS}"
	@echo "DOCS           :=${DOCS}"
	@echo "MANPAGES       :=${MANPAGES}"
	@echo
	@echo "DEST_BINS      :=${DEST_BINS}"
	@echo "DEST_LIBS      :=${DEST_LIBS}"
	@echo "DEST_TPLS :=${DEST_TPLS}"
	@echo "DEST_CONFS     :=${DEST_CONFS}"
	@echo "DEST_DOCS      :=${DEST_DOCS}"
	@echo "DEST_MANPAGES  :=${DEST_MANPAGES}"
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
		-e "s%@TPLSDIR@%${TPLSDIR}%" \
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
		-e "s%@TPLSDIR@%${TPLSDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $(addsuffix .bash,$@) > $@

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
		-e "s%@TPLSDIR@%${TPLSDIR}%" \
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
		-e "s%@TPLSDIR@%${TPLSDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $(addsuffix .man,$@) > $@

$(USER) :
	@echo adding ${USER} user
	@adduser --gid=${GROUPNUM} --system --shell=${BASH} --uid=${USERNUM} ${USER}

$(NOUSER) :
	@echo ${USER} already exists

$(GROUP) :
	@echo adding ${GROUP} group
	@addgroup --gid=${GROUPNUM} --system ${GROUP}

$(NOGROUP) :
	@echo ${GROUP} already exists

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


$(NO_SAVE_TPLS) :
	@echo no tplptrns to save

$(SAVE_TPLS) :
	@tar --preserve-permissions --create --gzip --file ${TPLDIR}/save.$(date +'%Y.%m.%d_%H.%M.%S') $(TPLS_TO_SAVE)

$(DEST_TPLS): | $(BACKUP_OLD_TPL) $(SRC_TPLS) 
	echo installing tplptrn files to ${TPLDIR}
	mkdir --parents ${TPLDIR}
	cp --force --recursive $(wildcard tplptrn/$(TPLVER)/*.tpl) $(TPLDIR)/$(TPLVER))
	chmod u=r,go= $(DEST_TPLS)
	chown --recursive ${USER}:${GROUP} ${TPLDIR}

$(NO_SAVE_CONF) :
	@echo no conf to save
	@tar --preserve-permissions --create --gzip --file ${CONFDIR}/save.$(date +'%Y.%m.%d_%H.%M.%S') ${CONFDIR}/*

$(SAVE_CONF) :

$(DEST_CONFS): $(BACKUP_OLD_CONF) $(SRC_CONFS)
	@echo installing configuration files to ${CONFDIR}
	@mkdir --parents ${CONFDIR}
	@cp --force --recursive $(CONFS) $(CONFDIR)
	@chmod u=rw,go= $(DEST_CONF)
	@chown --recursive ${USER}:${GROUP} ${CONFDIR}

$(DEST_DOCS): $(SRC_DOCS)
	@echo installing documentation to ${DOCDIR}
	@mkdir --parents ${DOCDIR}
	@cp --force --recursive $(DOCS) $(DOCDIR)
	@chmod a=r $(DEST_DOC)
	@chown --recursive ${USER}:${GROUP} ${DOCDIR}

$(DEST_MANPAGES): $(SRC_MANPAGES)
	@echo installing manual files to ${MANDIR}
	@mkdir --parents ${MANDIR}
	@cp --force --recursive $(MANPAGES) ${MANDIR}
	@chmod a=r $(DEST_MANPAGES})
	@chown --recursive ${USER}:${GROUP} ${MANDIR}

.PHONY: all options clean install uninstall nogrouptocreate nousertocreate
