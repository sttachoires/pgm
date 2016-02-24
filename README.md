pitrery: Point-In-Time Recovery (PITR) tools for PostgreSQL
===========================================================


FEATURES
--------

pitrery is set of tools to ease the management of PITR backups and
restores:

- Management of WAL segments archiving with compression to a host
  reachable with SSH or on the local machine

- Automation of the base backup procedure

- Restore to a particular date

- Management of backup retention


QUICK SETUP
-----------

1. Get the source

2. Edit the `config.mk`

3. Run `make` and `make install`

4. Copy `pitr.conf` to a new file to configure a particular backup

5. Edit this file to fit your system

6. Configure archiving (`archive_command = 'archive_xlog -C pitr %p'`)

7. Run `pitrery` to perform your backups and restores


DEVELOPMENT
-----------

The source code is available on github: https://github.com/dalibo/pitrery

pitrery is developped by Nicolas Thauvin under a classic 2 clauses BSD
license. See license block in the scripts or the COPYRIGHT file.
