# See COPYRIGHT file for copyright and license details.

include config.mk

DATE:=$(shell date +'%Y.%m.%d_%H.%M.%S')
SRC_BINS:=$(wildcard bin/*.bash)
SRC_COMMANDS:=$(wildcard command/*.bash)
SRC_UIS:=$(wildcard ui/*.bash)
SRC_SCRIPTS:=$(wildcard script/*.bash)
SRC_LIBS:=$(wildcard lib/*.include.bash)
SRC_TPLS:=$(wildcard tplptrn/*/*.tpl.ptrn)
SRC_CONFS:=$(wildcard conf/*.conf.sample)
SRC_LROTCONFS:=$(wildcard logrotate/*.conf.sample)
SRC_CONSTS:=$(wildcard conf/.*.conf.sample)
SRC_CONFSCRIPTS:=$(wildcard conf/*.bash)
SRC_DOCS:=COPYRIGHT INSTALL.md CONTRIBUTORS README.md TODO CHANGELOG
SRC_MANPAGES:=$(wildcard man/*.man)

BINS:=$(basename $(SRC_BINS))
COMMANDS:=$(basename $(SRC_COMMANDS))
UIS:=$(basename $(SRC_UIS))
SCRIPTS:=$(basename $(SRC_SCRIPTS))
LIBS:=$(basename $(SRC_LIBS))
CONFS:=$(basename $(SRC_CONFS))
LROTCONFS:=$(basename $(SRC_LROTCONFS))
CONSTS:=$(basename $(SRC_CONSTS))
CONFSCRIPTS:=$(basename $(SRC_CONFSCRIPTS))
MANPAGES:=$(basename $(SRC_MANPAGES))
TPLS:=$(basename $(SRC_TPLS))
DOCS:=$(SRC_DOCS)

DEST_BINS:=$(BINS:bin/%=${BINDIR}/%)
DEST_COMMANDS:=$(COMMANDS:command/%=${COMMANDDIR}/%)
DEST_UIS:=$(UIS:ui/%=${UIDIR}/%)
DEST_SCRIPTS:=$(SCRIPTS:script/%=${SCRIPTDIR}/%)
DEST_LIBS:=$(LIBS:lib/%=${LIBDIR}/%)
DEST_CONFS:=$(CONFS:conf/%=${CONFDIR}/%)
DEST_LROTCONFS:=$(LROTCONFS:logrotate/%=${LROTCONFDIR}/%)
DEST_CONSTS:=$(CONSTS:conf/%=${CONFDIR}/%)
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
	@echo "COMMANDDIR       =${COMMANDDIR}"
	@echo "UIDIR            =${UIDIR}"
	@echo "SCRIPTDIR        =${SCRIPTDIR}"
	@echo "LIBDIR           =${LIBDIR}"
	@echo "TPLDIR           =${TPLDIR}"
	@echo "CONFDIR          =${CONFDIR}"
	@echo "LROTCONFDIR      =${LROTCONFDIR}"
	@echo "DOCDIR           =${DOCDIR}"
	@echo "MANDIR           =${MANDIR}"
	@echo "LOGDIR           =${LOGDIR}"
	@echo
	@echo "SRC_BINS         =${SRC_BINS}"
	@echo "SRC_COMMANDS     =${SRC_COMMANDS}"
	@echo "SRC_UIS          =${SRC_UIS}"
	@echo "SRC_SCRIPTS      =${SRC_SCRIPTS}"
	@echo "SRC_LIBS         =${SRC_LIBS}"
	@echo "SRC_TPLS         =${SRC_TPLS}"
	@echo "SRC_CONFS        =${SRC_CONFS}"
	@echo "SRC_LROTCONFS    =${SRC_LROTCONFS}"
	@echo "SRC_CONSTS       =${SRC_CONSTS}"
	@echo "SRC_CONFSCRIPTS  =${SRC_CONFSCRIPTS}"
	@echo "SRC_DOCS         =${SRC_DOCS}"
	@echo "SRC_MANPAGES     =${SRC_MANPAGES}"
	@echo
	@echo "BINS             =${BINS}"
	@echo "COMMANDS         =${COMMANDS}"
	@echo "UIS              =${UIS}"
	@echo "SCRIPTS          =${SCRIPTS}"
	@echo "LIBS             =${LIBS}"
	@echo "TPLS             =${TPLS}"
	@echo "CONFS            =${CONFS}"
	@echo "LROTCONFS        =${LROTCONFS}"
	@echo "CONSTS           =${CONSTS}"
	@echo "CONFSCRIPTS      =${CONFSCRIPTS}"
	@echo "DOCS             =${DOCS}"
	@echo "MANPAGES         =${MANPAGES}"
	@echo
	@echo "DEST_BINS        =${DEST_BINS}"
	@echo "DEST_COMMANDS    =${DEST_COMMANDS}"
	@echo "DEST_UIS         =${DEST_UIS}"
	@echo "DEST_SCRIPTS     =${DEST_SCRIPTS}"
	@echo "DEST_LIBS        =${DEST_LIBS}"
	@echo "DEST_TPLS        =${DEST_TPLS}"
	@echo "DEST_CONFS       =${DEST_CONFS}"
	@echo "DEST_LROTCONFS   =${DEST_LROTCONFS}"
	@echo "DEST_CONSTS      =${DEST_CONSTS}"
	@echo "DEST_CONFSCRIPTS =${DEST_CONFSCRIPTS}"
	@echo "DEST_DOCS        =${DEST_DOCS}"
	@echo "DEST_MANPAGES    =${DEST_MANPAGES}"
	@echo
	@echo "######"
	@echo

all : bins commands uis scripts libs configs manpages templates docs
	@echo

install : all installdirs installbins installcommands installuis installscripts installlibs $(BACKUP_OLD_TPLS) installtpl $(BACKUP_OLD_CONFS) installconfs installdocs installmans cronjobs


checkinstall : 
	@echo $(shell $(BASH) $(BINDIR)/pgbrewer check)

bins : $(BINS)
	@echo

commands : $(COMMANDS)
	@echo

uis : $(UIS)
	@echo

scripts : $(SCRIPTS)
	@echo

libs : $(LIBS)
	@echo

configs : $(CONFS) $(CONFSCRIPTS) $(CONSTS)
	@echo

manpages : $(MANPAGES)
	@echo

templates : $(TPLS)
	@echo

docs : $(DOCS)
	@echo

installbins : $(DEST_BINS)
	@echo

installcommands : $(DEST_COMMANDS)
	@echo

installuis : $(DEST_UIS)
	@echo

installscripts : $(DEST_SCRIPTS)
	@echo

installlibs : $(DEST_LIBS)
	@echo

installconfs : $(DEST_CONFS) $(DEST_LROTCONFS) $(DEST_CONFSCRIPTS) $(DEST_CONSTS)
	@echo

installmans : $(DEST_MANPAGES)
	@echo

installtpl : $(DEST_TPLS)
	@echo

installdocs : $(DEST_DOCS)
	@echo

installdirs : $(PREFIX) $(BINDIR) $(COMMANDDIR) $(UIDIR) $(SCRIPTDIR) $(LIBDIR) $(CONFDIR) $(TPLDIR) $(LOGDIR) $(MANDIR) $(INVENTORYDIR) $(DOCDIR)
	@echo

uninstall :
	@echo removing all files from ${PREFIX}
	@rm -f $(DEST_BINS)
	@rm -f $(DEST_COMMANDS)
	@rm -f $(DEST_UIS)
	@rm -f $(DEST_SCRIPTS)
	@rm -f $(DEST_LIBS)
	@rm -f $(DEST_TPLS)
	@rm -f $(DEST_CONFS) $(DEST_LROTCONFS) $(DEST_CONFSCRIPTS) $(DEST_CONSTS)
	@rm -f $(DEST_DOCS)
	@rm -f $(DEST_MANPAGES)

clean :
	@echo cleaning
	@rm -f $(BINS)
	@rm -f $(COMMANDS)
	@rm -f $(UIS)
	@rm -f $(SCRIPTS)
	@rm -f $(LIBS)
	@rm -f $(TPLS)
	@rm -f $(CONFS) $(DEST_LROTCONFS) $(CONFSCRIPTS) $(DEST_CONSTS)
	@rm -f $(MANPAGES)
	@rm -f crontab.tmp


% : %.bash
	@echo translating paths in bash script $@
	@sed -e "s%@BASH@%${BASH}%" \
		-e "s%@USER@%${USER}%" \
		-e "s%@VERSION@%${VERSION}%" \
		-e "s%@PREFIX@%${PREFIX}%" \
		-e "s%@BINDIR@%${BINDIR}%" \
		-e "s%@COMMANDDIR@%${COMMANDDIR}%" \
		-e "s%@UIDIR@%${UIDIR}%" \
		-e "s%@SCRIPTDIR@%${SCRIPTDIR}%" \
		-e "s%@LIBDIR@%${LIBDIR}%" \
		-e "s%@CONFDIR@%${CONFDIR}%" \
		-e "s%@LROTCONFDIR@%${LROTCONFDIR}%" \
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
		-e "s%@COMMANDDIR@%${COMMANDDIR}%" \
		-e "s%@UIDIR@%${UIDIR}%" \
		-e "s%@SCRIPTDIR@%${SCRIPTDIR}%" \
		-e "s%@LIBDIR@%${LIBDIR}%" \
		-e "s%@CONFDIR@%${CONFDIR}%" \
		-e "s%@LROTCONFDIR@%${LROTCONFDIR}%" \
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
		-e "s%@COMMANDDIR@%${COMMANDDIR}%" \
		-e "s%@UIDIR@%${UIDIR}%" \
		-e "s%@SCRIPTDIR@%${SCRIPTDIR}%" \
		-e "s%@LIBDIR@%${LIBDIR}%" \
		-e "s%@CONFDIR@%${CONFDIR}%" \
		-e "s%@LROTCONFDIR@%${LROTCONFDIR}%" \
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
		-e "s%@COMMANDDIR@%${COMMANDDIR}%" \
		-e "s%@UIDIR@%${UIDIR}%" \
		-e "s%@SCRIPTDIR@%${SCRIPTDIR}%" \
		-e "s%@LIBDIR@%${LIBDIR}%" \
		-e "s%@CONFDIR@%${CONFDIR}%" \
		-e "s%@LROTCONFDIR@%${LROTCONFDIR}%" \
		-e "s%@DOCDIR@%${DOCDIR}%" \
		-e "s%@TPLDIR@%${TPLDIR}%" \
		-e "s%@LOGDIR@%${LOGDIR}%" \
		-e "s%@NAME@%${NAME}%" \
		-e "s%@INVENTORYDIR@%${INVENTORYDIR}%" \
		-e "s%@LOGROTATE@%${LOGROTATE}%" \
		-e "s%@MANDIR@%${MANDIR}%" $< > $@

$(PREFIX) $(BINDIR) $(COMMANDDIR) $(UIDIR) $(SCRIPTDIR) $(LIBDIR) $(CONFDIR) $(LROTCONFDIR) $(TPLDIR) $(LOGDIR) $(MANDIR) $(DOCDIR) $(INVENTORYDIR) :
	@echo creation of $@
	@mkdir --parents $@
	@chmod u=rwx,g=rx,o= $@

CRONTABTMP:=crontab.tmp
$(CRONTABTMP) : $(DEST_CONFS)
	@$(shell crontab -l | egrep -v "${CONFDIR}/logrotate.conf" > $@)
	@$(shell echo "# Logrotate for PGM" >> $@)
	@$(shell echo "*/10 * * * * ${LOGROTATE} --state=${CONFDIR}/logrotate.state ${CONFDIR}/logrotate.conf > ${LOGDIR}/logrotate.log 2>&1" >> $@)
	@echo ${CRONTABTMP} created

cronjobs : $(CRONTABTMP)
	@echo adding crontab logrotate job
	@crontab $<
	@echo

$(DEST_BINS) : $(BINS) $(BINDIR)
	@echo installing excecutable $@ to ${BINDIR}
	@cp --force $(patsubst $(BINDIR)/%,bin/%,$@) ${BINDIR}
	@chmod ug=rx,o= $@

$(DEST_COMMANDS) : $(COMMANDS) $(COMMANDDIR)
	@echo installing command $@ to ${COMMANDDIR}
	@cp --force $(patsubst $(COMMANDDIR)/%,command/%,$@) ${COMMANDDIR}
	@chmod ug=rx,o= $@

$(DEST_UIS) : $(UIS) $(UIDIR)
	@echo installing user interface $@ to ${UIDIR}
	@cp --force $(patsubst $(UIDIR)/%,ui/%,$@) ${UIDIR}
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
	@chmod ug=rw,o= $@

$(DEST_CONFS) : $(CONFS) $(CONFDIR)
	@echo installing configuration file $@ to ${CONFDIR}
	@cp --force $(patsubst $(CONFDIR)/%,conf/%,$@) ${CONFDIR}
	@chmod ug=rw,o= $@

$(DEST_LROTCONFS) : $(LROTCONFS) $(LROTCONFDIR)
	@echo installing configuration file $@ to ${LROTCONFDIR}
	@cp --force $(patsubst $(LROTCONFDIR)/%,logrotate/%,$@) ${LROTCONFDIR}
	@chmod ug=rw,o= $@

$(DEST_CONSTS) : $(CONSTS) $(CONFDIR)
	@echo installing configuration file $@ to ${CONFDIR}
	@cp --force $(patsubst $(CONFDIR)/%,conf/%,$@) ${CONFDIR}
	@chmod ug=r,o= $@

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
