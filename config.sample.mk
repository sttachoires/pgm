NAME:=pgm
VERSION:=0.02-dev

# Customize below to fit your system

# Bash is mandatory
BASH:=/bin/bash

# paths
PREFIX:=/home/pgm
LOGROTATE:=/usr/sbin/logrotate
DBPREFIX:=/home/pgm/pgdb

BINDIR:=$(PREFIX)/bin
SCRIPTDIR:=$(PREFIX)/script
LIBDIR:=$(PREFIX)/lib/$(NAME)
CONFDIR:=$(PREFIX)/etc/$(NAME)
DOCDIR:=$(PREFIX)/share/$(NAME)
MANDIR:=$(PREFIX)/share/$(NAME)/man/man1
TPLDIR:=$(PREFIX)/templates/$(NAME)
LOGDIR:=$(PREFIX)/log/$(NAME)
INVENTORYDIR:=$(PREFIX)/inventory/$(NAME)
