NAME:=pgbrewer
VERSION:=0.02-dev

# Customize below to fit your system
# Those constant will be valued at install, no change hereafter

# Mandatory executables should be usefull to force a static value...maybe not
# Where is your bash. Usualy in your PATH, but who knows.
BASH:=/bin/bash

# Where is logrotate. Usualy in your PATH, but who knows.
LOGROTATE:=/usr/sbin/logrotate

# Path that NEEDS TO BE SET
#
# The root directory where all will be installed.
# You have to own this directory with full rights on it
#PREFIX:=/usr/local
#PREFIX:=/home/${USER}
#PREFIX:=/home/pgbrewer
PREFIX:=SET IT NOW


# Paths that should be change at your convenience here
# But will never changer after that.

# You have to own these directories with full rights on them
# Where the binary pgbrewer will be.
BINDIR:=$(PREFIX)/bin

# Where the command binaries will be.
COMMANDDIR:=$(PREFIX)/command

# Where the user interface profiles will be.
UIDIR:=$(PREFIX)/ui

# Where the administration scripts will be (initd for exemple)
SCRIPTDIR:=$(PREFIX)/script

# Where the libraries will be, .include executables files
LIBDIR:=$(PREFIX)/lib/$(NAME)

# Where the configuration files will be
#CONFDIR:=/etc/$(NAME)
CONFDIR:=$(PREFIX)/etc/$(NAME)

# Logrotate configuration file
LROTCONFDIR:=$(PREFIX)/etc/logrotate

# Where docs will be
DOCDIR:=$(PREFIX)/share/$(NAME)

# Where the manpages will be
MANDIR:=$(PREFIX)/share/$(NAME)/man/man1

# pgbrewer templates directories place where dbas could edit them
#TPLDIR:=$(PREFIX)/share/$(NAME)/templates
TPLDIR:=$(PREFIX)/templates/$(NAME)

# pgbrewer log directory
#LOGDIR:=/var/log/$(NAME)
LOGDIR:=$(PREFIX)/log/$(NAME)

# The End
