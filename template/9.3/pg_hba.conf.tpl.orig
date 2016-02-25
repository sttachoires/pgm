# =============================================
#
#  D O    N E V E R    E D I T    M A N U A L Y
#
#  U S E    D E D I C A T E D    S C R I P T S
#    S E E    O P E R A T I O N S   G U I D E
#
# =============================================
# PostgreSQL Client Authentication Configuration File
# ===================================================
# Refer to the "Client Authentication" section in the
# PostgreSQL documentation for a complete description
# of this file.  A short synopsis follows.
# This file controls: which hosts are allowed to connect, how clients
# are authenticated, which PostgreSQL user names they can use, which
# databases they can access.  Records take one of these forms:
# local      DATABASE  USER  METHOD  [OPTIONS]
# host       DATABASE  USER  CIDR-ADDRESS  METHOD  [OPTIONS]
# hostssl    DATABASE  USER  CIDR-ADDRESS  METHOD  [OPTIONS]
# hostnossl  DATABASE  USER  CIDR-ADDRESS  METHOD  [OPTIONS]
# (The uppercase items must be replaced by actual values.)
# TYPE	DATABASE	USER		CIDR-ADDRESS	METHOD
# "local" is for Unix domain socket connections only
local	all		${PGM_USER}			trust
# IPv4 local connections:
host	all		${PGM_USER}	127.0.0.1/32	trust
host	all		all		0.0.0.0/0	md5
# IPv6 local connections:
#host	all		all		::1/128		md5
