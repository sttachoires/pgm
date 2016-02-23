restore_command = 'rsync ${PGM_PGARCHIVELOG_DIR}/%f %p'
archive_cleanup_command = 'pg_archivecleanup  ${PGM_PGARCHIVELOG_DIR}/ %r'
