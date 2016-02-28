# See COPYRIGHT file for copyright and license details.

include config.mk

DATE:=$(shell date +'%Y.%m.%d_%H.%M.%S')

SRC_BINS:=$(wildcard bin/*.bash)
SRC_SCRIPTS:=$(wildcard script/*.bash)
SRC_LIBS:=$(wildcard lib/*.include.bash)
SRC_TPLS:=$(wildcard tplptrn/*/*.tpl.ptrn)
SRC_CONFS:=$(wildcard conf/*.conf.sample)
SRC_DOCS:=COPYRIGHT INSTALL.md CONTRIBUTORS README.md TODO CHANGELOG
SRC_MANPAGES:=$(wildcard man/*.man)

BINS:=$(basename $(SRC_BINS))
SCRIPTS:=$(basename $(SRC_SCRIPTS))
LIBS:=$(basename $(SRC_LIBS))
CONFS:=$(basename $(SRC_CONFS))
MANPAGES:=$(basename $(SRC_MANPAGES))
TPLS:=$(basename $(SRC_TPLS))
DOCS:=$(SRC_DOCS)
BASH_PROFILE:="$(PREFIX)/.bash_profile"

DEST_BINS:=$(BINS:bin/%=${BINDIR}/%)
DEST_SCRIPTS:=$(SCRIPTS:script/%=${SCRIPTDIR}/%)
DEST_LIBS:=$(LIBS:lib/%=${LIBDIR}/%)
DEST_CONFS:=$(CONFS:conf/%=${CONFDIR}/%)
DEST_MANPAGES:=$(MANPAGES:man/%=${MANDIR}/%)
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

SRC_INITD=$(SCRIPTDIR)/initd
DEST_INITD=/etc/init.d/pgm

cronjobs: crontab.tmp $(USERCREATE)
	@echo adding crontab logrotate job
	@crontab -u ${USER} $<
	@echo

crontab.tmp : $(CONFDIR)/logrotate.conf $(USERCREATE)
	@crontab -u ${USER} -l | egrep -v "$(CONFDIR)/logrotate.conf"; fi > $@
	@printf "$(CRONREPORT)*/10 * * * * logrotate --state=$(CONFDIR)/logrotate.state $(CONFDIR)/logrotate.conf >/dev/null 2>&1\n" >> $@

options :
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
	@echo "SCRIPTDIR        =${SCRIPTDIR}"
	@echo "LIBDIR           =${LIBDIR}"
	@echo "TPLDIR           =${TPLDIR}"
	@echo "CONFDIR          =${CONFDIR}"
	@echo "DOCDIR           =${DOCDIR}"
	@echo "MANDIR           =${MANDIR}"
	@echo "LOGDIR           =${LOGDIR}"
	@echo "INVENTORYDIR     =${INVENTORYDIR}"
	@echo "BASH_PROFILE     =${BASH_PROFILE}"
	@echo
	@echo "SRC_BINS         =${SRC_BINS}"
	@echo "SRC_SCRIPTS      =${SRC_SCRIPTS}"
	@echo "SRC_LIBS         =${SRC_LIBS}"
	@echo "SRC_TPLS         =${SRC_TPLS}"
	@echo "SRC_CONFS        =${SRC_CONFS}"
	@echo "SRC_DOCS         =${SRC_DOCS}"
	@echo "SRC_MANPAGES     =${SRC_MANPAGES}"
	@echo
	@echo "BINS             =${BINS}"
	@echo "SCRIPTS          =${SCRIPTS}"
	@echo "LIBS             =${LIBS}"
	@echo "TPLS             =${TPLS}"
	@echo "CONFS            =${CONFS}"
	@echo "DOCS             =${DOCS}"
	@echo "MANPAGES         =${MANPAGES}"
	@echo
	@echo "DEST_BINS        =${DEST_BINS}"
	@echo "DEST_SCRIPTS     =${DEST_SCRIPTS}"
	@echo "DEST_LIBS        =${DEST_LIBS}"
	@echo "DEST_TPLS        =${DEST_TPLS}"
	@echo "DEST_CONFS       =${DEST_CONFS}"
	@echo "DEST_DOCS        =${DEST_DOCS}"
	@echo "DEST_MANPAGES    =${DEST_MANPAGES}"
	@echo
	@echo "USERCREATE       =${USERCREATE}"
	@echo "GROUPCREATE      =${GROUPCREATE}"
	@echo "TPLS_TO_SAVE     =${TPLS_TO_SAVE}"
	@echo "BACKUP_OLD_TPLS  =${BACKUP_OLD_TPLS}"
	@echo "CONFS_TO_SAVE    =${CONFS_TO_SAVE}"
	@echo "BACKUP_OLD_CONFS =${BACKUP_OLD_CONFS}"

	@echo "######"
	@echo

all : bins scripts libs configs manpages templates docs
	@echo

check : 
	@echo $(shell $(BASH) bin/pgm_check)

install : all usergroup installdirs $(BASH_PROFILE) installbins installscripts installlibs $(BACKUP_OLD_TPLS) installtpl $(BACKUP_OLD_CONFS) installconfs installdocs installmans initd cronjobs


initd : $(DEST_INITD)
	@echo

checkinstall : 
	@echo $(shell $(BASH) $(BINDIR)/pgm_check)

bins : $(BINS)
	@echo

scripts : $(SCRIPTS)
	@echo

libs : $(LIBS)
	@echo

configs : $(CONFS)
	@echo

manpages : $(MANPAGES)
	@echo

templates : $(TPLS)
	@echo

docs : $(DOC)
	@echo


installmans : $(DEST_MANPAGES)
	@echo

installdocs : $(DEST_DOCS)
	@echo

installconfs : $(DEST_CONFS)
	@echo

installtpl : $(DEST_TPLS)
	@echo

usergroup : $(GROUPCREATE) $(USERCREATE)
	@echo

installdirs : $(PREFIX) $(BINDIR) $(SCRIPTDIR) $(LIBDIR) $(CONFDIR) $(TPLDIR) $(LOGDIR) $(MANDIR) $(INVENTORYDIR) $(DOCDIR)
	@echo

installbins : $(DEST_BINS)
	@echo

installscripts : $(DEST_SCRIPTS)
	@echo

installlibs : $(DEST_LIBS)
	@echo

uninstall :
	@echo removing all files from ${PREFIX}
	@rm -f $(DEST_BINS)
	@rm -f $(DEST_SCRIPTS)
	@rm -f $(DEST_LIBS)
	@rm -f $(DEST_TPLS)
	@rm -f $(DEST_CONFS)
	@rm -f $(DEST_DOCS)
	@rm -f $(DEST_MANPAGES)

clean :
	@echo cleaning
	@rm -f $(BINS)
	@rm -f $(SCRIPTS)
	@rm -f $(LIBS)
	@rm -f $(TPLS)
	@rm -f $(CONFS)
	@rm -f $(MANPAGES)


% : %.bash
	@echo translating paths in bash script $@
	@sed -e "s%@BASH@%${BASH}%" \
		-e "s%@USER@%${USER}%" \
		-e "s%@VERSION@%${VERSION}%" \
		-e "s%@PREFIX@%${PREFIX}%" \
		-e "s%@BINDIR@%${BINDIR}%" \
		-e "s%@SCRIPTDIR@%${SCRIPTDIR}%" \
		-e "s%@LIBDIR@%${LIBDIR}%" \
		-e "s%@CONFDIR@%${CONFDIR}%" \
		-e "s%@DOCDIR@%${DOCDIR}%" \
		-e "s%@USERNUM@%${USERNUM}%" \
		-e "s%@GROUP@%${GROUP}%" \
		-e "s%@GROUPNUM@%${GROUPNUM}%" \
		-e "s%@TPLDIR@%${TPLDIR}%" \
		-e "s%@LOGDIR@%${LOGDIR}%" \
		-e "s%@NAME@%${NAME}%" \
		-e "s%@INVENTORYDIR@%${INVENTORYDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $< > $@

%.tpl : %.tpl.ptrn
	@echo translating paths in template $@
	@sed -e "s%@BASH@%${BASH}%" \
		-e "s%@USER@%${USER}%" \
		-e "s%@VERSION@%${VERSION}%" \
		-e "s%@PREFIX@%${PREFIX}%" \
		-e "s%@BINDIR@%${BINDIR}%" \
		-e "s%@SCRIPTDIR@%${SCRIPTDIR}%" \
		-e "s%@LIBDIR@%${LIBDIR}%" \
		-e "s%@CONFDIR@%${CONFDIR}%" \
		-e "s%@DOCDIR@%${DOCDIR}%" \
		-e "s%@USERNUM@%${USERNUM}%" \
		-e "s%@GROUP@%${GROUP}%" \
		-e "s%@GROUPNUM@%${GROUPNUM}%" \
		-e "s%@TPLDIR@%${TPLDIR}%" \
		-e "s%@LOGDIR@%${LOGDIR}%" \
		-e "s%@NAME@%${NAME}%" \
		-e "s%@INVENTORYDIR@%${INVENTORYDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $< > $@

%.conf : %.conf.sample
	@echo translating paths in configuration file $@
	@sed -e "s%@BASH@%${BASH}%" \
		-e "s%@USER@%${USER}%" \
		-e "s%@VERSION@%${VERSION}%" \
		-e "s%@PREFIX@%${PREFIX}%" \
		-e "s%@BINDIR@%${BINDIR}%" \
		-e "s%@SCRIPTDIR@%${SCRIPTDIR}%" \
		-e "s%@LIBDIR@%${LIBDIR}%" \
		-e "s%@CONFDIR@%${CONFDIR}%" \
		-e "s%@DOCDIR@%${DOCDIR}%" \
		-e "s%@USERNUM@%${USERNUM}%" \
		-e "s%@GROUP@%${GROUP}%" \
		-e "s%@GROUPNUM@%${GROUPNUM}%" \
		-e "s%@TPLDIR@%${TPLDIR}%" \
		-e "s%@LOGDIR@%${LOGDIR}%" \
		-e "s%@NAME@%${NAME}%" \
		-e "s%@INVENTORYDIR@%${INVENTORYDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $< > $@

%.1 : %.1.man
	@echo translating paths in manual page $@
	@sed -e "s%@BASH@%${BASH}%" \
		-e "s%@USER@%${USER}%" \
		-e "s%@VERSION@%${VERSION}%" \
		-e "s%@PREFIX@%${PREFIX}%" \
		-e "s%@BINDIR@%${BINDIR}%" \
		-e "s%@SCRIPTDIR@%${SCRIPTDIR}%" \
		-e "s%@LIBDIR@%${LIBDIR}%" \
		-e "s%@CONFDIR@%${CONFDIR}%" \
		-e "s%@DOCDIR@%${DOCDIR}%" \
		-e "s%@USERNUM@%${USERNUM}%" \
		-e "s%@GROUP@%${GROUP}%" \
		-e "s%@GROUPNUM@%${GROUPNUM}%" \
		-e "s%@TPLDIR@%${TPLDIR}%" \
		-e "s%@LOGDIR@%${LOGDIR}%" \
		-e "s%@NAME@%${NAME}%" \
		-e "s%@INVENTORYDIR@%${INVENTORYDIR}%" \
		-e "s%@MANDIR@%${MANDIR}%" $< > $@

$(PREFIX) $(BINDIR) $(SCRIPTDIR) $(LIBDIR) $(CONFDIR) $(TPLDIR) $(LOGDIR) $(MANDIR) $(DOCDIR) $(INVENTORYDIR) : $(USERCREATE) $(GROUPCREATE)
	@echo creation of $@
	@mkdir --parents $@
	@chmod u=rwx,g=rx,o= $@
	@chown ${USER}:${GROUP} $@

$(DEST_INITD) : $(SRC_INITD) $(DEST_SCRIPTS)
	@echo "Copying new init.d script"
	@cp $< $@
	@chmod u+x $@

$(BASH_PROFILE) : $(PREFIX) $(USERCREATE) $(GROUPCREATE)
	@echo creation of ${BASH_PROFILE}
	@touch ${BASH_PROFILE}
	@echo "export PATH=\"${BINDIR}:${PATH}\"" >> ${BASH_PROFILE}
	@echo "export MANPATH=\"${MANDIR}:${MANPATH}\"" >> ${BASH_PROFILE}
	@echo "alias ll='ls -laF $*'" >> ${BASH_PROFILE}
	@echo "alias pgmsql='pgm_psql $*'" >> ${BASH_PROFILE}
	@chmod u=rw,g=r,o= ${BASH_PROFILE}
	@chown ${USER}:${GROUP} ${BASH_PROFILE}
	@echo

$(USER) : $(GROUPCREATE)
	@echo adding ${USER} user
	@adduser --gid=${GROUPNUM} --system --shell=${BASH} --uid=${USERNUM} --home=${PREFIX} ${USER} > /dev/null

$(NOUSER) : $(GROUPCREATE)
	@echo ${USER} already exists, you should include ${BASH_PROFILE} to his .bash_profile

$(GROUP) :
	@echo adding ${GROUP} group
	@addgroup --gid=${GROUPNUM} --system ${GROUP} > /dev/null

$(NOGROUP) :
	@echo ${GROUP} already exists

$(DEST_BINS) : $(BINS) $(BINDIR) $(USERCREATE) $(GROUPCREATE)
	@echo installing excecutable $@ to ${BINDIR}
	@cp --force $(patsubst $(BINDIR)/%,bin/%,$@) ${BINDIR}
	@chmod u=rx,go= $@
	@chown ${USER}:${GROUP} $@

$(DEST_SCRIPTS) : $(SCRIPTS) $(SCRIPTDIR) $(USERCREATE) $(GROUPCREATE)
	@echo installing scripts $@ to ${SCRIPTDIR}
	@cp --force $(patsubst $(SCRIPTDIR)/%,script/%,$@) ${SCRIPTDIR}
	@chmod u=rx,go= $@
	@chown ${USER}:${GROUP} $@

$(DEST_LIBS) : $(LIBS) $(LIBDIR) $(USERCREATE) $(GROUPCREATE)
	@echo installing library $@ into ${LIBDIR}
	@cp --force $(patsubst $(LIBDIR)/%,lib/%,$@) ${LIBDIR}
	@chmod u=r,go= $@
	@chown ${USER}:${GROUP} $@

$(NO_SAVE_TPLS) : $(TPLDIR) $(USERCREATE) $(GROUPCREATE)
	@echo no tplptrns to save
	@echo

$(SAVE_TPLS) : $(TPLDIR) $(USERCREATE) $(GROUPCREATE)
	@echo saving old templates ${TPLS_TO_SAVE}
	@tar --preserve-permissions --exclude ${TPLDIR}/save.* --create --gzip --file ${TPLDIR}/save.${DATE} ${TPLS_TO_SAVE} > /dev/null 2>&1
	@chmod u=r,go= ${TPLDIR}/save.${DATE}
	@chown ${USER}:${GROUP} ${TPLDIR}/save.${DATE}
	@echo

$(DEST_TPLS) : $(TPLS) $(TPLDIR) $(USERCREATE) $(GROUPCREATE)
	@echo installing template files $@ to ${TPLDIR}
	@mkdir --parents $(dir $@)
	@cp $(patsubst $(TPLDIR)/%,tplptrn/%,$@) $@
	@chmod u=r,go= $@
	@chown ${USER}:${GROUP} $@

$(NO_SAVE_CONFS) : $(CONFDIR) $(USERCREATE) $(GROUPCREATE)
	@echo no conf to save
	@echo

$(SAVE_CONFS) : $(CONFDIR) $(USERCREATE) $(GROUPCREATE)
	@echo saving old configuration ${CONFS_TO_SAVE}
	@tar --preserve-permissions --exclude ${CONFDIR}/save.* --create --gzip --file ${CONFDIR}/save.${DATE} ${CONFS_TO_SAVE} > /dev/null 2>&1
	@chmod u=r,go= ${CONFDIR}/save.${DATE}
	@chown ${USER}:${GROUP} ${CONFDIR}/save.${DATE}
	@echo

$(DEST_CONFS) : $(BACKUP_OLD_CONF) $(CONFS) $(CONFDIR) $(USERCREATE) $(GROUPCREATE)
	@echo installing configuration files $@ to ${CONFDIR}
	@cp --force $(patsubst $(CONFDIR)/%,conf/%,$@) ${CONFDIR}
	@chmod u=rw,go= $@
	@chown ${USER}:${GROUP} $@

$(DEST_DOCS) : $(DOCS) $(DOCDIR) $(USERCREATE) $(GROUPCREATE)
	@echo installing documentation $@ to ${DOCDIR}
	@cp --force $(patsubst $(DOCDIR)/%,%,$@) ${DOCDIR}
	@chmod a=rX $@
	@chown ${USER}:${GROUP} $@

$(DEST_MANPAGES) : $(MANPAGES) $(MANDIR) $(USERCREATE) $(GROUPCREATE)
	@echo installing manual files $@ to ${MANDIR}
	@cp --force $(patsubst $(MANDIR)/%,man/%,$@) ${MANDIR}
	@chmod a=r $@
	@chown ${USER}:${GROUP} $@

.PHONY: all options clean install uninstall nogroup nouser nosavetpls nosaveconfs
