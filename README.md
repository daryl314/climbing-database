![Database interface](/climbingdb.png?raw=true "Database interface")

## Installation

### Install prerequisites

* sqlite3

### Create a new sqlite database

```
sqlite3 climbing.db < make_database.sql
```

### Create users

For each user to be created, run an INSERT command with the first name,
last name, and display name of the climber
```
sqlite3 climbing.db "INSERT INTO "climbers" (fname,lname,display) VALUES('Daryl','St. Laurent','Daryl');"
```

## Usage

* Start server: `./server.sh`
* Database administration: `http://localhost:5000/`
* Send data visualization: `http://localhost:5000/static/sends.html`

## Administration

* Create a backup of the database: `./run_backup`
* Compare current database to most recent backup (requires colordiff): `./db_compare`
