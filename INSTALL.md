Introduction
============

pgbrewer is a set og Bash scripts to manage multiple PostgreSQL version
with multiple instances, with multiple database in it, without 
loosing your temper.

============

Prerequisites
-------------

pgbrewer is a set of bash scripts, so bash is required. Apart from bash,
standard tools found on any Linux server are needed: `grep`, `sed`, `awk`,
`tar`, `gzip`, `ssh`, `scp`
To execute your order pgbrewer needs some more things:
`python-dev`, `perl-dev`, `readline-dev`, `zlib-dev`, `rsync`, `gcc`,
`make`, `ssl-dev`

Installation from the sources
-----------------------------

The latest version of can be downloaded from:

https://github.com/sttachoires/pgbrewer/archive/master.zip

First unpack the zip:

    unzip master.zip


Then, go to the `pgbrewer-master` directory and edit `config.mk` to fit your
system. Once done run `make` (or `gmake`) to replace the interpreter and
paths in the scripts:

    make all


Finally, install it, as root: 

    make install

Then

    make checkinstall

By default, the files are installed in `/home/pgbrewer`:

* scripts are installed in `/home/pgbrewer/bin`

* actions used by pgbrewer are installed in `/home/pgbrewer/lib/pgbrewer`

* configuration samples are installed in `/home/pgbrewer/etc/pgbrewer`

* manual pages are installed in `/home/pgbrewer/share/pgbrewer/man`

