# Installation

## Install prerequisites
* sqlite3
* node.js and npm
* coffeescript

## Create a new sqlite database
```
sqlite3 climbing.db < make_database.sql
```

## Create users
For each user to be created, run an INSERT command with the first name,
last name, and display name of the climber
```
sqlite3 climbing.db "INSERT INTO "climbers" (fname,lname,display) VALUES('Daryl','St. Laurent','Daryl');"
```

## Install node packages (only if included packages do not work)
From root directory of project:
```
npm install sqlite3 express lodash body-parser coffee-script
```

# Usage

* Start server: `./database.coffee`
* Database administration: `http://localhost:3000/`
* Send data visualization: `http://localhost:3000/sends.html`

# Administration

* Create a backup of the database: `./run_backup`
* Compare current database to most recent backup (requires colordiff): `./db_compare`
