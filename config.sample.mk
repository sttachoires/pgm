NAME = pgm
VERSION = 0.01-dev

# Customize below to fit your system

# Bash is mandatory
BASH = /bin/bash

# paths
USER = postgres
USERNUM = 533
GROUP = dba
GROUPNUM = 533
PREFIX = /home/pgm
BINDIR = ${PREFIX}/bin
LIBDIR = ${PREFIX}/lib/${NAME}
CONFDIR = ${PREFIX}/etc/${NAME}
DOCDIR = ${PREFIX}/share/${NAME}
MANDIR = ${PREFIX}/share/man
TPLDIR = ${PREFIX}/templates/${NAME}
LOGDIR = ${PREFIX}/log
