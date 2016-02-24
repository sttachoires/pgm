Introduction
============

pgm is a set og Bash scripts to manage multiple PostgreSQL version
with multiple instances, with multiple database in it, without 
loosing your temper.

============

Prerequisites
-------------

pgm is a set of bash scripts, so bash is required. Apart from bash,
standard tools found on any Linux server are needed: `grep`, `sed`, `awk`,
`tar`, `gzip`, `ssh`, `scp`
To execute your order pgm needs some more things:
`python-dev`, `perl-dev`, `readline-dev`, `zlib-dev`, `rsync`, `gcc`,
`make`, `ssl-dev`

Installation from the sources
-----------------------------

The latest version of can be downloaded from:

https://github.com/sttachoires/pgm/archive/master.zip

First unpack the zip:

    unzip master.zip


Then, go to the `pitrery-x.y` directory and edit `config.mk` to fit your
system. Once done run `make` (or `gmake`) to replace the interpreter and
paths in the scripts:

    make


Finally, install it, as root: 

    make install


By default, the files are installed in `/usr/local`:

* scripts are installed in `/usr/local/bin`

* actions used by pitrery are installed in `/usr/local/lib/pgm`

* configuration samples are installed in `/usr/local/etc/pgm`

* manual pages are installed in `/usr/local/share/man`

