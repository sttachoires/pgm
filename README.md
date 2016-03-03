PGM Set of scripts to help manage  PostgreSQL
==============================================


FEATURES
--------

pgm is a set of bash scripts that helps manage multiple version
of PostgreSQL with multiple instances, all on the same server.

All install with current user.
PostgreSQL instances will be launch as current user too.
Prepare PostgreSQL prerequisits
Prepare ssl, perl, and python (for now you need to be root)

QUICK SETUP
-----------

1. Get the source

2. Copy config.sample.mk to config.mk

3. Edit the `config.mk`, specified prefix (PREFIX and DBPREFIX) should
   exits and must be read, write, execute for current user.

3. Run `make` and `make install`

4. `source .pgm_profile`

5. Run `pgm_server_install /path/to/package/dir versionlabel`

6. Try `pgm_instance_create versionlabel instancename`

7. Try `pgm_<TAB>`, test, and tell me.


DEVELOPMENT
-----------

The source code is available on github: https://github.com/sttachoires

pgm is developped by Stephane Tachoires under a classic 2 clauses BSD
license. See license block in the scripts or the COPYRIGHT file.
