#!/bin/bash

##############################################################
# Application parameters
# Check and change as needed
##############################################################

# Name of the Geonames database
# Call it what you want, allows you to have multiple versions
DB_GEONAMES="geonames2"

# Code version (github repo for this code)
# Assign tag and use tag #
# Otherwise entire commit hash or leave blank
VERSION="2.0"

# Target URL for geonames data
# Complete GADM world package:
URL_DB_DATA="http://download.geonames.org/export/dump/"

# Separate directory for postal codes
URL_PCODES="https://download.geonames.org/export/zip/"

# Data version
DB_DATA_VERSION="2020-04-21"

# Base application directory
APP_BASE_DIR="/home/boyle/bien/geonames";

# Applications source code directory
APP_DIR="${APP_BASE_DIR}/src"

# Path to db_config.sh
# For production, keep outside app working directory & supply
# absolute path
# For development, if keep inside working directory, then supply
# relative path
# Omit trailing slash
db_config_path="${APP_BASE_DIR}/config"

# Path to general function directory
# If directory is outside app working directory, supply
# absolute path, otherwise supply relative path
# Omit trailing slash
#functions_path=""
functions_path="${APP_BASE_DIR}/src/includes"

# Path to data directory
# DB input data from geonames will be saved here
# If directory is outside app working directory, supply
# absolute path, otherwise use relative path (i.e., no 
# forward slash at start).
# Recommend keeping outside app directory
# Omit trailing slash
DATA_DIR="${APP_BASE_DIR}/data"

# Makes user_admin the owner of the db and all objects in db
# If leave user_admin blank ("") then database will be owned
# by whatever user you use to run this script, and postgis tables
# will belong to postgres
USER_ADMIN="bien"		# Admin user

# Give user_read select permission on the database
# If leave blank ("") user_read will not be added and only
# you will have access to db
USER_READ="bien_private"	# Read only user

##############################################################
# Application parameters
# Check and change as needed
##############################################################

# Names of files from geonames download
FILES="allCountries.zip alternateNames.zip userTags.zip admin1CodesASCII.txt admin2Codes.txt countryInfo.txt featureCodes_en.txt iso-languagecodes.txt timeZones.txt"

# Postal code data directory
# This should be a subdirectory of the data directory
# Omit slashes
PCDIR="pcodes"
########################################################
# Misc parameters
########################################################

# Destination email for process notifications
# You must supply a valid email if you used the -m option
email="bboyle@email.arizona.edu"

# Short name for this operation, for screen echo and 
# notification emails. Number suffix matches script suffix
pname="Build database $DB_GEONAMES"

# General process name prefix for email notifications
pname_header_prefix="Notification: process"

# Log file parameters
today=$(date +"%Y-%m-%d")
glogfile="log/log_${today}.txt"
appendlog="false"