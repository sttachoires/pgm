# See COPYRIGHT file for copyright and license details.

include config.mk

DATE:=$(shell date +'%Y.%m.%d_%H.%M.%S')
SRC_BINS:=$(wildcard bin/*.bash)
SRC_SCRIPTS:=$(wildcard script/*.bash)
SRC_LIBS:=$(wildcard lib/*.include.bash)
SRC_TPLS:=$(wildcard tplptrn/*/*.tpl.ptrn)
SRC_CONFS:=$(wildcard conf/*.conf.sample)
SRC_CONFSCRIPTS:=$(wildcard conf/*.bash)
SRC_DOCS:=COPYRIGHT INSTALL.md CONTRIBUTORS README.md TODO CHANGELOG
SRC_MANPAGES:=$(wildcard man/*.man)

BINS:=$(basename $(SRC_BINS))
SCRIPTS:=$(basename $(SRC_SCRIPTS))
LIBS:=$(basename $(SRC_LIBS))
CONFS:=$(basename $(SRC_CONFS))
CONFSCRIPTS:=$(basename $(SRC_CONFSCRIPTS))
MANPAGES:=$(basename $(SRC_MANPAGES))
TPLS:=$(basename $(SRC_TPLS))
DOCS:=$(SRC_DOCS)
BASH_PROFILE:="$(PREFIX)/.pgm_profile"

DEST_BINS:=$(BINS:bin/%=${BINDIR}/%)
DEST_SCRIPTS:=$(SCRIPTS:script/%=${SCRIPTDIR}/%)
DEST_LIBS:=$(LIBS:lib/%=${LIBDIR}/%)
DEST_CONFS:=$(CONFS:conf/%=${CONFDIR}/%)
DEST_CONFSCRIPTS:=$(CONFSCRIPTS:conf/%=${CONFDIR}/%)
DEST_MANPAGES:=$(MANPAGES:man/%=${MANDIR}/%)
DEST_TPLS:=$(TPLS:tplptrn/%=${TPLDIR}/%)
DEST_DOCS:=$(DOCS:%=${DOCDIR}/%)

options :
	@echo
	@echo "######"
	@echo "${NAME} ${VERSION} install options:"
	@echo "######"
	@echo "BASH             =${BASH}"
	@echo "PREFIX           =${PREFIX}"
	@echo "LOGROTATE        =${LOGROTATE}"
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
	@echo "SRC_CONFSCRIPTS  =${SRC_CONFSCRIPTS}"
	@echo "SRC_DOCS         =${SRC_DOCS}"
	@echo "SRC_MANPAGES     =${SRC_MANPAGES}"
	@echo
	@echo "BINS             =${BINS}"
	@echo "SCRIPTS          =${SCRIPTS}"
	@echo "LIBS             =${LIBS}"
	@echo "TPLS             =${TPLS}"
	@echo "CONFS            =${CONFS}"
	@echo "CONFSCRIPTS      =${CONFSCRIPTS}"
	@echo "DOCS             =${DOCS}"
	@echo "MANPAGES         =${MANPAGES}"
	@echo
	@echo "DEST_BINS        =${DEST_BINS}"
	@echo "DEST_SCRIPTS     =${DEST_SCRIPTS}"
	@echo "DEST_LIBS        =${DEST_LIBS}"
	@echo "DEST_TPLS        =${DEST_TPLS}"
	@echo "DEST_CONFS       =${DEST_CONFS}"
	@echo "DEST_CONFSCRIPTS =${DEST_CONFSCRIPTS}"
	@echo "DEST_DOCS        =${DEST_DOCS}"
	@echo "DEST_MANPAGES    =${DEST_MANPAGES}"
	@echo
	@echo "######"
	@echo

all : bins scripts libs configs manpages templates docs
	@echo

install : all installdirs $(BASH_PROFILE) installbins installscripts installlibs $(BACKUP_OLD_TPLS) installtpl $(BACKUP_OLD_CONFS) installconfs installdocs installmans cronjobs


checkinstall : 
	@echo $(shell $(BASH) $(BINDIR)/pgm_check)

bins : $(BINS)
	@echo

cronjobs : crontabcreate
	@echo adding crontab logrotate job
	@crontab $<
	@echo

crontabcreate : $(CONFDIR)/logrotate.conf
	@crontab -l | egrep -v "$(CONFDIR)/logrotate.conf" > $@
	@echo '*/10 * * * * $(LOGROTATE) --state=$(CONFDIR)/logrotate.state $(CONFDIR)/logrotate.conf > $(LOGDIR)/logrotate.log 2>&1' >> $@
	@echo OK

scripts : $(SCRIPTS)
	@echo

libs : $(LIBS)
	@echo

configs : $(CONFS) $(CONFSCRIPTS)
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

installconfs : $(DEST_CONFS) $(DEST_CONFSCRIPTS)
	@echo

installtpl : $(DEST_TPLS)
	@echo

installbins : $(DEST_BINS)
	@echo

installscripts : $(DEST_SCRIPTS)
	@echo

installlibs : $(DEST_LIBS)
	@echo

installdirs : $(PREFIX) $(BINDIR) $(SCRIPTDIR) $(LIBDIR) $(CONFDIR) $(TPLDIR) $(LOGDIR) $(MANDIR) $(INVENTORYDIR) $(DOCDIR)
	@echo

uninstall :
	@echo removing all files from ${PREFIX}
	@rm -f $(DEST_BINS)
	@rm -f $(DEST_SCRIPTS)
	@rm -f $(DEST_LIBS)
	@rm -f $(DEST_TPLS)
	@rm -f $(DEST_CONFS) $(DEST_CONFSCRIPTS)
	@rm -f $(DEST_DOCS)
	@rm -f $(DEST_MANPAGES)

clean :
	@echo cleaning
	@rm -f $(BINS)
	@rm -f $(SCRIPTS)
	@rm -f $(LIBS)
	@rm -f $(TPLS)
	@rm -f $(CONFS) $(CONFSCRIPTS)
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
		-e "s%@TPLDIR@%${TPLDIR}%" \
		-e "s%@LOGDIR@%${LOGDIR}%" \
		-e "s%@NAME@%${NAME}%" \
		-e "s%@INVENTORYDIR@%${INVENTORYDIR}%" \
		-e "s%@LOGROTATE@%${LOGROTATE}%" \
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
		-e "s%@TPLDIR@%${TPLDIR}%" \
		-e "s%@LOGDIR@%${LOGDIR}%" \
		-e "s%@NAME@%${NAME}%" \
		-e "s%@INVENTORYDIR@%${INVENTORYDIR}%" \
		-e "s%@LOGROTATE@%${LOGROTATE}%" \
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
		-e "s%@TPLDIR@%${TPLDIR}%" \
		-e "s%@LOGDIR@%${LOGDIR}%" \
		-e "s%@NAME@%${NAME}%" \
		-e "s%@INVENTORYDIR@%${INVENTORYDIR}%" \
		-e "s%@LOGROTATE@%${LOGROTATE}%" \
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
		-e "s%@TPLDIR@%${TPLDIR}%" \
		-e "s%@LOGDIR@%${LOGDIR}%" \
		-e "s%@NAME@%${NAME}%" \
		-e "s%@INVENTORYDIR@%${INVENTORYDIR}%" \
		-e "s%@LOGROTATE@%${LOGROTATE}%" \
		-e "s%@MANDIR@%${MANDIR}%" $< > $@

$(PREFIX) $(BINDIR) $(SCRIPTDIR) $(LIBDIR) $(CONFDIR) $(TPLDIR) $(LOGDIR) $(MANDIR) $(DOCDIR) $(INVENTORYDIR) :
	@echo creation of $@
	@mkdir --parents $@
	@chmod u=rwx,g=rx,o= $@

$(BASH_PROFILE) : $(PREFIX)
	@echo creation of ${BASH_PROFILE}
	touch ${BASH_PROFILE}
	echo "export PATH=\"${BINDIR}:${PATH}\"" >> ${BASH_PROFILE}
	echo "export MANPATH=\"${MANDIR}:${MANPATH}\"" >> ${BASH_PROFILE}
	echo "alias ll='ls -laF $*'" >> ${BASH_PROFILE}
	echo "alias pgmsql='pgm_psql $*'" >> ${BASH_PROFILE}
	chmod u=rw,g=r,o= ${BASH_PROFILE}
	@echo

$(DEST_BINS) : $(BINS) $(BINDIR)
	@echo installing excecutable $@ to ${BINDIR}
	@cp --force $(patsubst $(BINDIR)/%,bin/%,$@) ${BINDIR}
	@chmod ug=rx,o= $@

$(DEST_SCRIPTS) : $(SCRIPTS) $(SCRIPTDIR)
	@echo installing scripts $@ to ${SCRIPTDIR}
	@cp --force $(patsubst $(SCRIPTDIR)/%,script/%,$@) ${SCRIPTDIR}
	@chmod ug=rx,o= $@

$(DEST_LIBS) : $(LIBS) $(LIBDIR)
	@echo installing library $@ into ${LIBDIR}
	@cp --force $(patsubst $(LIBDIR)/%,lib/%,$@) ${LIBDIR}
	@chmod ug=r,g= $@

$(DEST_TPLS) : $(TPLS) $(TPLDIR)
	@echo installing template files $@ to ${TPLDIR}
	@mkdir --parents $(dir $@)
	@cp --force $(patsubst $(TPLDIR)/%,tplptrn/%,$@) $@
	@chmod ug=r,o= $@

$(DEST_CONFS) : $(CONFS) $(CONFDIR)
	@echo installing configuration file $@ to ${CONFDIR}
	@cp --force $(patsubst $(CONFDIR)/%,conf/%,$@) ${CONFDIR}
	@chmod ug=rw,o= $@

$(DEST_CONFSCRIPTS) : $(CONFSCRIPTS) $(CONFDIR)
	@echo installing configuration script $@ to ${CONFDIR}
	@cp --force $(patsubst $(CONFDIR)/%,conf/%,$@) ${CONFDIR}
	@chmod ug=rwx,o= $@

$(DEST_DOCS) : $(DOCS) $(DOCDIR)
	@echo installing documentation $@ to ${DOCDIR}
	@cp --force $(patsubst $(DOCDIR)/%,%,$@) ${DOCDIR}
	@chmod a=r $@

$(DEST_MANPAGES) : $(MANPAGES) $(MANDIR)
	@echo installing manual files $@ to ${MANDIR}
	@cp --force $(patsubst $(MANDIR)/%,man/%,$@) ${MANDIR}
	@chmod a=r $@

.PHONY: all options clean install uninstall
