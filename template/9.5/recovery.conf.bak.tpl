restore_command = 'rsync ${PGM_PGARCHIVELOG}/%f %p'
archive_cleanup_command = 'pg_archivecleanup  ${PGM_PGARCHIVELOG}/ %r'
