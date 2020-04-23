#!/bin/bash

#########################################################################
# Purpose: Creates geonames database & populates with latest data from
#	geonames download 
#
# Usage:	sudo -u postgres ./geonames.sh
#
# Warnings:
#	1. Must run as user postgres
#	2. Data directory (set in params file) must exist and must be owned
#		by postgres (e.g., chgrp postgres <data_directory>)
#
# Adapted in part from the following script:
#	http://forum.geonames.org/gforum/posts/list/15/926.page
#
# Date created: 21 April 2020
# Author: Brad Boyle (bboyle@email.arizona.edu)
#########################################################################

: <<'COMMENT_BLOCK_x'
COMMENT_BLOCK_x
#echo "EXITING script `basename "$BASH_SOURCE"`"; exit 0

######################################################
# Set basic parameters, functions and options
######################################################

# Enable the following for strict debugging only:
#set -e

# The name of this file. Tells sourced scripts not to reload general  
# parameters and command line options as they are being called by  
# another script. Allows component scripts to be called individually  
# if needed
master=`basename "$0"`

# Get working directory
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

# Set includes directory path, relative to $DIR
includes_dir=$DIR"/includes"

# Load parameters, functions and get command-line options
source "$includes_dir/startup_master.sh"


# Includes directory absolute path
# Needed for operations inside data directory
# Must declare after startup_master
includes_dir_abs="${APP_DIR}/includes"

######################################################
# Custom confirmation message. 
# Will only be displayed if -s (silent) option not used.
######################################################

# Admin user message
curr_user="$(whoami)"
user_admin_disp=$curr_user
if [[ "$USER_ADMIN" != "" ]]; then
	user_admin_disp="$USER_ADMIN"
fi

# Read-only user message
user_read_disp="[n/a]"
if [[ "$USER_READ" != "" ]]; then
	user_read_disp="$USER_READ"
fi

# Reset confirmation message
msg_conf="$(cat <<-EOF

Run process '$pname' using the following parameters: 

Geonames main:			$URL_DB_DATA
Geonames postal codes:		$URL_PCODES
Geonames version:		$DB_DATA_VERSION
Data directory:			$DATA_DIR
Geonames DB name:		$DB_GEONAMES
Current user:			$curr_user
Admin user/db owner:		$user_admin_disp
Additional read-only user:	$user_read_disp

EOF
)"		
confirm "$msg_conf"

# Start time, send mail if requested and echo begin message
source "$includes_dir/start_process.sh"  

#########################################################################
# Main
#########################################################################

: <<'COMMENT_BLOCK_x'
COMMENT_BLOCK_x

############################################
# Create database
############################################

# Run pointless command to trigger sudo password request, 
# needed below. Should remain in effect for all
# sudo commands in this script, regardless of sudo timeout
sudo pwd >/dev/null



echo "***** WARNING: script block(s) deactivated! ****"
: <<'COMMENT_BLOCK_1'



# Check if db already exists
if psql -lqt | cut -d \| -f 1 | grep -qw "$DB_GEONAMES"; then
	# Reset confirmation message
	msg_conf="WARNING! Database '$DB_GEONAMES' already exists. Replace?"
	confirm "$msg_conf"

	echoi $e -n "Dropping database '$DB_GEONAMES'..."
	sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql --set ON_ERROR_STOP=1 -q -c "DROP DATABASE $DB_GEONAMES" 
	source "$includes_dir/check_status.sh"  
fi

echoi $e -n "Creating database '$DB_GEONAMES'..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql --set ON_ERROR_STOP=1 -q -c "CREATE DATABASE $DB_GEONAMES" 
source "$includes_dir/check_status.sh"  

echoi $e -n "Adding unaccent extension..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -d $DB_GEONAMES -q << EOF
\set ON_ERROR_STOP on
DROP EXTENSION IF EXISTS unaccent;
CREATE EXTENSION unaccent;
EOF
echoi $i "done"

echoi $e -n "Creating geonames tables...."
PGOPTIONS='--client-min-messages=warning' psql $DB_GEONAMES --set ON_ERROR_STOP=1 -q -f sql/create_geonames_tables.sql
source "$includes_dir/check_status.sh"

############################################
# Import geonames files
############################################

echoi $e "Importing geonames files to directory $(pwd):"
cd "$DATA_DIR"

for i in $FILES; do
	# -l option prevents logfile error
	echoi $e -l -n "- "$i"..."
	wget -N -q "${URL_DB_DATA}/$i" # get newer files
	RETVAL=$?
	[ $RETVAL -ne 0 ] && echo "cannot download $i file: Aborting. Error="$RETVAL && exit $RETVAL
	
	if [ $i -nt "_$i" ] || [ ! -e "_$i" ] ; then
		cp -p $i "_$i"
		if [ `expr index zip $i` -eq 1 ]; then
			unzip -o -u -q $i
		fi
		
		# Remove headers and comments from selected files
		case "$i" in
			iso-languagecodes.txt)
				tail -n +2 iso-languagecodes.txt > iso-languagecodes.txt.tmp;
			;;
			countryInfo.txt)
				grep -v '^#' countryInfo.txt | head -n -2 > countryInfo.txt.tmp;
			;;
			timeZones.txt)
				tail -n +2 timeZones.txt > timeZones.txt.tmp;
			;;
		esac
		echoi $e -l "downloaded";
	else
		echoi $e -l "already the latest version"
	fi
done

# Move to data directory 
pcpath=$DATA_DIR"/"$PCDIR
mkdir -p $pcpath
cd $pcpath

# Download postal codes from separate url
echoi $e -n -l "- ${PCDIR}/allCountries.zip' (postal codes)..."
wget -q -N "${URL_PCODES}/allCountries.zip"
unzip -u -q $pcpath/allCountries.zip
echoi  $e -l "done"

############################################
# Insert the data
############################################

# Back to original working directory
cd "$DIR"

echoi $e -n "Clearing tables..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql $DB_GEONAMES --set ON_ERROR_STOP=1 -q <<EOT
TRUNCATE geoname;
TRUNCATE postalcodes;
TRUNCATE timezones;
TRUNCATE featurecodes;
TRUNCATE admin1codesascii;
TRUNCATE admin2codesascii;
TRUNCATE iso_languagecodes;
TRUNCATE countryinfo;
TRUNCATE alternatename;
TRUNCATE continentcodes;
EOT
source "$includes_dir/check_status.sh"

echoi $e "Inserting data to tables:"

echoi $e -n "- geoname..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql $DB_GEONAMES --set ON_ERROR_STOP=1 -q <<EOT
copy geoname (geonameid,name,asciiname,alternatenames,latitude,longitude,fclass,fcode,country,cc2,admin1,admin2,admin3,admin4,population,elevation,gtopo30,timezone,moddate) from '${DATA_DIR}/allCountries.txt' null as '';
EOT
source "$includes_dir/check_status.sh"

echoi $e -n "- postalcodes..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql $DB_GEONAMES --set ON_ERROR_STOP=1 -q <<EOT
copy postalcodes (countrycode,postalcode,placename,admin1name,admin1code,admin2name,admin2code,admin3name,admin3code,latitude,longitude,accuracy) from '${DATA_DIR}/${PCDIR}/allCountries.txt' WITH CSV DELIMITER E'\t' QUOTE E'\b' NULL AS '';
EOT
source "$includes_dir/check_status.sh"

echoi $e -n "- timezones..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql $DB_GEONAMES --set ON_ERROR_STOP=1 -q <<EOT
copy timezones (countrycode,timezoneid,gmt_offset,dst_offset,raw_offset) from '${DATA_DIR}/timeZones.txt.tmp' null as '';
EOT
source "$includes_dir/check_status.sh"

echoi $e -n "- featurecodes..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql $DB_GEONAMES --set ON_ERROR_STOP=1 -q <<EOT
copy featurecodes (code,name,description) from '${DATA_DIR}/featureCodes_en.txt' null as '';
EOT
source "$includes_dir/check_status.sh"

echoi $e -n "- admin1codesascii..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql $DB_GEONAMES --set ON_ERROR_STOP=1 -q <<EOT
copy admin1codesascii (code,name,nameascii,geonameid) from '${DATA_DIR}/admin1CodesASCII.txt' null as '';
EOT
source "$includes_dir/check_status.sh"

echoi $e -n "- admin2codesascii..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql $DB_GEONAMES --set ON_ERROR_STOP=1 -q <<EOT
copy admin2codesascii (code,name,nameascii,geonameid) from '${DATA_DIR}/admin2Codes.txt' null as '';
EOT
source "$includes_dir/check_status.sh"

echoi $e -n "- iso_languagecodes..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql $DB_GEONAMES --set ON_ERROR_STOP=1 -q <<EOT
copy iso_languagecodes (iso_639_3,iso_639_2,iso_639_1,language_name) from '${DATA_DIR}/iso-languagecodes.txt.tmp' null as '';
EOT
source "$includes_dir/check_status.sh"

echoi $e -n "- countryinfo..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql $DB_GEONAMES --set ON_ERROR_STOP=1 -q <<EOT
copy countryinfo (iso_alpha2,iso_alpha3,iso_numeric,fips_code,country,capital,areainsqkm,population,continent,tld,currency_code,currency_name,phone,postal,postalregex,languages,geonameid,neighbours,equivalent_fips_code) from '${DATA_DIR}/countryInfo.txt.tmp' null as '';
EOT
source "$includes_dir/check_status.sh"

echoi $e -n "- alternatename..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql $DB_GEONAMES --set ON_ERROR_STOP=1 -q <<EOT
copy alternatename (alternatenameid,geonameid,isolanguage,alternatename,ispreferredname, isshortname, iscolloquial, ishistoric) from '${DATA_DIR}/alternateNames.txt' null as '';
EOT
source "$includes_dir/check_status.sh"

echoi $e -n "- continentcodes..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql $DB_GEONAMES --set ON_ERROR_STOP=1 -q <<EOT
INSERT INTO continentcodes VALUES ('AF', 'Africa', 6255146);
INSERT INTO continentcodes VALUES ('AS', 'Asia', 6255147);
INSERT INTO continentcodes VALUES ('EU', 'Europe', 6255148);
INSERT INTO continentcodes VALUES ('NA', 'North America', 6255149);
INSERT INTO continentcodes VALUES ('OC', 'Oceania', 6255150);
INSERT INTO continentcodes VALUES ('SA', 'South America', 6255151);
INSERT INTO continentcodes VALUES ('AN', 'Antarctica', 6255152);
EOT
source "$includes_dir/check_status.sh"

echoi $e -n "Fixing postalcodes and admincodes tables..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql $DB_GEONAMES --set ON_ERROR_STOP=1 -q -f "${APP_DIR}/sql/admincodes.sql"
source "$includes_dir/check_status.sh"

############################################
# Set ownership and permissions
############################################

if [ "$USER_ADMIN" != "" ]; then
	echoi $e "Changing database ownership and permissions:"

	echoi $e -n "- Changing DB owner to '$USER_ADMIN'..."
	sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql --set ON_ERROR_STOP=1 -q -c "ALTER DATABASE $DB_GEONAMES OWNER TO $USER_ADMIN" 
	source "$includes_dir/check_status.sh"  

	echoi $e -n "- Granting permissions..."
	sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -q <<EOF
	\set ON_ERROR_STOP on
	REVOKE CONNECT ON DATABASE $DB_GEONAMES FROM PUBLIC;
	GRANT CONNECT ON DATABASE $DB_GEONAMES TO $USER_ADMIN;
	GRANT ALL PRIVILEGES ON DATABASE $DB_GEONAMES TO $USER_ADMIN;
EOF
	echoi $i "done"

	echoi $e "- Transferring ownership to user '$USER_ADMIN':"
	# Note: views not changed as all at this point are postgis relations

	echoi $e -n "-- Tables..."
	for tbl in `psql -qAt -c "select tablename from pg_tables where schemaname='public';" $DB_GEONAMES` ; do  sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -q -c "alter table \"$tbl\" owner to $USER_ADMIN" $DB_GEONAMES ; done
	source "$includes_dir/check_status.sh"  

	echoi $e -n "-- Sequences..."
	for tbl in `psql -qAt -c "select sequence_name from information_schema.sequences where sequence_schema = 'public';" $DB_GEONAMES` ; do  sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -q -c "alter sequence \"$tbl\" owner to $USER_ADMIN" $DB_GEONAMES ; done
	source "$includes_dir/check_status.sh"  
fi

if [[ ! "$USER_READ" == "" ]]; then
	echoi $e -n "- Granting read access to \"$USER_READ\"..."
	sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql -q <<EOF
	\set ON_ERROR_STOP on
	REVOKE CONNECT ON DATABASE $DB_GEONAMES FROM PUBLIC;
	GRANT CONNECT ON DATABASE $DB_GEONAMES TO $USER_READ;
	\c $DB_GEONAMES
	GRANT USAGE ON SCHEMA public TO $USER_READ;
	GRANT SELECT ON ALL TABLES IN SCHEMA public TO $USER_READ;
EOF
	echoi $i "done"
fi 

######################################################
# Add PKs, indexes and FK constraints
# This takes a LOOOONG time! Hours!
######################################################

echoi $e -n "Indexing tables..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql $DB_GEONAMES --set ON_ERROR_STOP=1 -q -f "${APP_DIR}/sql/index_geonames_tables.sql"
source "$includes_dir/check_status.sh"

echoi $e -n "Optimizing indexes..."
sudo -Hiu postgres PGOPTIONS='--client-min-messages=warning' psql --set ON_ERROR_STOP=1 -d $DB_GEONAMES -q -c "VACUUM ANALYZE $DB_GEONAMES"
source "$includes_dir/check_status.sh"

######################################################
# Report total elapsed time and exit
######################################################

source "$includes_dir/finish.sh"
