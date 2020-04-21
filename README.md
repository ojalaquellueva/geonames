# Build Geonames PostgreSQL database

Author: Brad Boyle (bboyle@email.arizona.edu)  
Date created: 21 April 2020  


## Contents

[Overview](#overview)  
[Software](#software)  
[Permissions](#permissions)  
[Installation and configuration](#installation-and-configuration)  
[Usage](#usage)  

## Overview

Creates & populates a local postgres instance of the Geonames Geographical Place Names Database (www.https://www.geonames.org/). 

## Software

Ubuntu 16.04 or higher  
PostgreSQL/psql 12.2, or higher (PostGIS extension will be installed by this script)

## Permissions

* Scripts must be run by user with sudo. User must also have authorization to connect to postgres (as specified in `pg_hba.conf`) without a password. 
* Admin-level and read-only Postgres users for the gadm database (specified in `params.sh`) must already exist, with authorization to connect to postgres.

## Installation and configuration

```
# Create application base directory
mkdir -p geonames
cd geonames

# Create application code directory
mkdir src

# Install repo to application code directory
cd src
git clone https://github.com/ojalaquellueva/geonames.git

# Move data and sensitive parameters directories outside of code directory
# Be sure to change paths to these directories (in params.sh) accordingly
mv data ../
mv config ../
```

## Usage

1. Set parameters in `params.sh`.
2. Set passwords and other sensitive parameters in `config/db_config.sh`.
2. Run the master script, `geonames.sh`.

### Syntax

```
./geonames.sh [options]
```

### Command line options
-m: Send notification emails  
-n: No warnings: suppress confirmations but not progress messages  
-s: Silent mode: suppress all confirmations & progress messages  
* All other options must be set in params.inc

### Example:

```
./geonames.sh -m -s
```
* Runs silently without terminal echo
* Sends notification message at start and completion


