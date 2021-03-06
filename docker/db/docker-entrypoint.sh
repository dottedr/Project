#!/bin/bash
set -e

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
	set -- /usr/sbin/mysqld "$@"
fi

if [ "$1" = '/usr/sbin/mysqld' ]; then
	# read DATADIR from the MySQL config
	DATADIR="/var/lib/mysql"
    #"$("$@" --verbose --help 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')"
	
	if [ ! -d "$DATADIR/mysql" ]; then
		if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" ]; then
			echo >&2 'error: database is uninitialized and MYSQL_ROOT_PASSWORD not set'
			echo >&2 '  Did you forget to add -e MYSQL_ROOT_PASSWORD=... ?'
			exit 1
		fi
		
		echo 'Initializing database'
		/usr/bin/mysql_install_db --datadir="$DATADIR"
		echo 'Database initialized'
		
		# These statements _must_ be on individual lines, and _must_ end with
		# semicolons (no line breaks or comments are permitted).
		# TODO proper SQL escaping on ALL the things D:
		
		tempSqlFile='/tmp/mysql-first-time.sql'
		cat > "$tempSqlFile" <<-EOSQL
			-- What's done in this file shouldn't be replicated
			--  or products like mysql-fabric won't work
			SET @@SESSION.SQL_LOG_BIN=0;
			
			DELETE FROM mysql.user ;
			CREATE USER 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' ;
			GRANT ALL ON *.* TO 'root'@'%' WITH GRANT OPTION ;
			DROP DATABASE IF EXISTS test ;
		EOSQL
		
		if [ "$MYSQL_DATABASE" ]; then
			echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" >> "$tempSqlFile"
		fi
		
		if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
			echo "CREATE USER '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD' ;" >> "$tempSqlFile"
			
			if [ "$MYSQL_DATABASE" ]; then
				echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* TO '$MYSQL_USER'@'%' ;" >> "$tempSqlFile"
			fi
		fi
		
		echo 'FLUSH PRIVILEGES ;' >> "$tempSqlFile"

		if [ -d "/tmp/initsql" ]; then
		    echo "Adding initial SQL config files from /tmp/initsql"
		    cat /tmp/initsql/* >> "${tempSqlFile}_2"
		    
		    echo "Init file contains:"
		    cat "$tempSqlFile"
		    $@ --init-file="$tempSqlFile"&
		    sleep 3
		    mysql -u root --password="${MYSQL_ROOT_PASSWORD}" < "${tempSqlFile}_2"
		    pkill mysqld
		    i="0"; while ! pgrep mysqld && [ $i -lt 10 ]; do i=$[$i+1]; sleep 1; done
		fi
	fi
	
    echo "$DATADIR"
	chown -R mysql:mysql "$DATADIR" 2> /dev/null
fi

exec "$@"
