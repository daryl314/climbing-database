#!/usr/bin/env coffee
# create js file for sends_static.html:
#   ./database.coffee dump > public/send_data.js

# DEPENDENCIES
# npm install sqlite3 express lodash body-parser coffee-script

# create database connection
sqlite3 = require('sqlite3').verbose()
db = new sqlite3.Database('climbing.db')

# create REST API
express = require('express')
restapi = express()

# handle JSON form data
bodyParser = require('body-parser')
restapi.use(bodyParser.json())

# load lodash module
_ = require('lodash')

# load coffeescript module
fs = require('fs')
coffee = require('coffee-script')

################################
# CREATE SENDS.JS IF REQUESTED #
################################

if process.argv[2]? and process.argv[2] == 'dump'
  db.serialize ->
    db.all 'SELECT * FROM SENDS', (err,row) ->
      console.log "window.data = "
      console.log row
  return

###########################
# QUERY UTILITY FUNCTIONS #
###########################

# execute a query and return results
getQuery = (query, res) ->
  console.log "Executing query: #{query}"
  db.all query, (err, row) ->
    if !err
      res.send row
    else
      console.err err

# execute a query without returning results
executeQuery = (query, res, okCode) ->
  console.log "Executing query: #{query}"
  db.run query, (err, row) ->
      if err
          console.err err
          res.status 500  # internal service error
      else
          res.status okCode
      res.end()

###############################
# REST REGISTRATION FUNCTIONS #
###############################

# function to register a GET query (READ)
registerGet = (table, id) ->
  restapi.get "/#{table}", (req, res) ->      # all data
    db.serialize ->
      getQuery "SELECT * FROM #{table}", res
  restapi.get "/#{table}/:id", (req, res) ->  # specific item
    db.serialize ->
      getQuery "SELECT * FROM #{table} WHERE #{id} = #{req.params.id}", res

# function to register a POST query (CREATE)
registerPost = (table, id) ->
  restapi.post "/#{table}", (req, res) ->
    console.log "POST: #{JSON.stringify(req.body)}"
    k = _.keys(req.body)
    v = _.map k, (x) ->
      if _.isNumber(req.body[x]) then req.body[x] else "'#{req.body[x]}'"
    query = "INSERT INTO #{table} (#{k.join(',')}) VALUES (#{v.join(',')})"
    console.log "Executing query: #{query}"
    db.run query, (err, row) ->
      if err
        console.err err
        res.status 500      # 500 = internal service error
      else
        console.log "-> #{this.lastID}"
        out = {}
        out[id] = this.lastID
        res.send(out)
        res.status(201)     # 201 = created
      res.end()

# function to register a PUT query (UPDATE)
registerPut = (table, id) ->
  restapi.put "/#{table}/:id", (req, res) ->
    console.log "PUT: #{JSON.stringify(req.body)}"
    assignmentData = _.map( req.body, (v,k) ->
      k + "=" + if _.isNumber(v) then v else "'#{{v}}'"
    ).join(', ')
    query = "UPDATE #{table} SET #{assignmentData} WHERE #{id}=#{req.params.id}"
    executeQuery query, res, 202    # 202 = Accepted

# function to register a DELETE query (DELETE)
registerDelete = (table, id) ->
  restapi.delete "/#{table}/:id", (req, res) ->
    console.log "DELETE: #{JSON.stringify(req.body)}"
    query = "DELETE FROM #{table} WHERE #{id} = #{req.params.id}"
    executeQuery query, res, 200    # 200 = OK

##############################
# REGISTER DATABASE HANDLERS #
##############################

# make tableData global
tableData = {}

# register handlers
db.serialize ->
  db.all 'SELECT name, type FROM sqlite_master', (err,row) ->
    console.log(tableData = row)
    _.each tableData, (x) ->
      db.serialize ->
        if x.type == 'view'
          console.log "Registering view at /#{x.name}"
          registerGet x.name
        else
          db.all "PRAGMA table_info(#{x.name})", (err,row) ->
            x.id = _.find(row, {pk:1}).name
            console.log "Registering table at /#{x.name} (id = #{x.id})"
            registerGet     x.name, x.id
            registerPost    x.name, x.id
            registerPut     x.name, x.id
            registerDelete  x.name, x.id

###################
# CONTENT SERVING #
###################

# serve static content at /
restapi.use(express.static(__dirname + '/public'))

# return table data at /tableData
restapi.get '/tableData', (req, res) ->
  res.json(tableData)

# listen on port 3000
restapi.listen(3000)
console.log "Web server running at http://localhost:3000"

# register a coffeescript handler
registerCoffeeHandler = (file) ->
  jsFile = file.replace /\.coffee$/, '.js'
  restapi.get "/#{jsFile}", (req,res) ->
    res.header 'Content-Type', 'application/x-javascript'
    cs = fs.readFileSync "coffee/#{file}", 'ascii'
    js = coffee.compile cs
    console.log "Serving coffee/#{file} as /#{jsFile}"
    res.send js

# serve coffeescript files in coffee folder as javascript equivalents
for file in fs.readdirSync('coffee')
  if file.match /\.coffee$/
    registerCoffeeHandler file
