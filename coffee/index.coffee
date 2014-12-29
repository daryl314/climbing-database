# TODO
# test tool
# write code to compare two sqlite databases and generate a diff report
# compiling: coffee -p index.coffee > index.js


# =============================================================================
#
# Query strings
#
# =============================================================================

# query string for sends
sendQuery = '''
  SELECT
    ascents.send_date         AS Date,
    climbers.display          AS Climber,
    routes.name               AS Route,
    ascent_styles.style_name  AS Style,
    grades.grade              AS Grade
  FROM ascents
  INNER JOIN climbers       ON ascents.climber_id = climbers.climber_id
  INNER JOIN routes         ON ascents.route_id   = routes.route_id
  INNER JOIN ascent_styles  ON ascents.style_id   = ascent_styles.style_id
  NATURAL JOIN grades
  WHERE climbers.enabled=1
  ORDER BY Date DESC
  '''

# query string for route data
routeQuery = '''
  SELECT
    routes.route_id     AS ID,
    routes.name         AS Route,
    grades.grade        AS Grade,
    cliffs.cliff_name   AS Cliff,
    areas.area_name     AS Area,
    grades.grade_sort   AS GradeSort,
    grades.grade_class  AS RouteType
  FROM routes
    NATURAL JOIN grades
    NATURAL JOIN cliffs
    NATURAL JOIN areas
  ORDER BY Route
  '''


# =============================================================================
#
# Query data as Backbone Collection
#
# =============================================================================

# function to convert a table to a Backbone collection
convertTable = (x, tbl, id) ->

  # extend Backbone.Collection to contain data
  collection = Backbone.Collection.extend

    # store name of first column (assuming first column is ID)
    # and the name of the source table in the database in the model
    model: Backbone.Model.extend( idAttribute: id, table: tbl )

    # store database column names in 'columns' property
    columns: _.keys(x[0])

    # store id column in collection too
    idAttribute: id

    # url for model on server
    url: "/#{tbl}"

    # function to return the row where the value in column 'a' equals 'b'
    lookup: (a,b) -> @findWhere _.object([a],[b])

  # convert input data to the extended collection
  obj = new collection(x)

  # bind to collection events
  obj.on

    # SQL code to handle model UPDATE
    change: (obj, opt) ->
      obj.save()
      _.each obj.changed, (k,v) ->
        _.each _.keys(obj.changed), (k) ->
          console.log "#{k}: #{obj.previousAttributes()[k]} -> #{obj.changed[k]}"

    # SQL code to handle model CREATE
    create: (obj) ->
      keyText = _.keys(obj.attributes).join(',')
      valText = "'" + _.values(obj.attributes).join("','") + "'"
      console.log "INSERT INTO #{obj.table} (#{keyText}) VALUES (#{valText})"

    # SQL code to handle model DELETE
    remove: (obj) ->
      console.log "DELETE FROM #{obj.table} WHERE #{obj.idAttribute} = #{obj.id}"
      obj.destroy()

  # return object
  return obj

# =============================================================================
#
# Convert a Backbone.js collection (or array of models) to an HTML table
#
# =============================================================================

# convert a Backbone.js collection (or array of models) to an HTML table
collectionToTable = (m) ->

  # convert to an array of models
  m = m.toArray() unless _.isArray(m)

  # extract common keys
  k = _.keys( m[0].toJSON() )

  # create HTML for rows
  tr = _.map m, (a) ->
    td = _.map(k, (b)->a.get(b))
    "<tr data-id='#{a.id}'><td>#{ td.join('</td><td>') }</td></tr>"

  # return HTML for the whole table
  return """<table border=1>
              <thead>
                <tr><th>#{k.join('</th><th>')}</th></tr>
              </thead>
              <tbody> #{tr.join("\n")} </tbody>
            </table>"""

# =============================================================================
#
# Query class
#
# =============================================================================

# Note that "objects" referenced in this class refer to database table entries
# that are elements in one of the Backbone.js database query collections above
# that serve as low-level database connections.

class Query


  ###########################
  # QUERY STRING PROCESSING #
  ###########################

  # constructor: pass query string and a structure of backbone.js tables
  constructor: (queryString, @tables) ->
    @parseString queryString  # extract information from query string
    @parseSelected()          # process SELECT clause
    @parseJoins()             # process JOIN clause(s)
    @parseNaturalJoins()      # process NATURAL JOIN clause(s)

  # extract data from query string with regular expressions
  parseString: (str) ->
    @string         = str.replace(/[\s\r\n]+/g, ' ').trim()
    @selected       = @string.match(/SELECT (.*) FROM/)[1].split(', ')
    @from           = @string.match(/FROM (\w+)/)[1]
    @joins          = @string.match(/(INNER|NATURAL) JOIN \w+( ON \w+\.\w+ = \w+\.\w+)?/g)
    @orderBy        = ( @string.match(/ORDER BY (\w+)/) or [null,null] )[1]
    @sortDirection  = ( @string.match(/ORDER BY \w+ (ASC|DESC)/) or [null,'ASC'] )[1]
    whereRegex      = /WHERE ([\w\.]+)\s*(=|<|<=|>|>=|<>)\s*(('.*?')|([\d\.]+))/
    @where          = @string.match(whereRegex)[1..3] if @string.match(whereRegex)

  # extract data from SELECT clauses
  parseSelected: ->
    @columnData = _.map @selected, (x) -> {
      displayAs:    x.match(/(?:AS |\.)(\w+)$/)[1]  # SELECT alias (AS ...)
      sourceTable:  x.match(/^\w+/)[0]              # SELECT source table
      sourceColumn: x.match(/\.(\w+)/)[1]           # SELECT source column
    }

  # extract data from JOIN clause(s):
  #   - join type (type)
  #   - table and column on left side of join (lTbl, lCol)
  #   - table and column on right side of join (rTbl, rCol)
  parseJoins: ->
    @joinData = _.map @joins, (x,idx) ->
      joinData = x.match(/([A-Z]+ JOIN) (.*)/) # join type and "everything else"
      if joinData[1] == 'NATURAL JOIN'
        out = { type:joinData[1], rTbl:joinData[2] }
      else
        a = x.match(/(\w+)\.(\w+) = (\w+)\.(\w+)/)
        out = { type:joinData[1], lTbl:a[1], lCol:a[2], rTbl:a[3], rCol:a[4] }
      out

  # extract information from NATURAL JOIN clauses
  parseNaturalJoins: ->
    _.each @joinData, (x,idx) =>
      if x.type == 'NATURAL JOIN'
        parents = [@from].concat _.pluck(_.first(@joinData,idx), 'rTbl')
        parentColumns = _.map( parents, (x)=>@tables[x].columns )
        parentIndex = _.findIndex parentColumns, (a) =>
          _.intersection(a, @tables[x.rTbl].columns).length > 0
        commonColumns = _.intersection tables[x.rTbl].columns, tables[parents[parentIndex]].columns
        x.lTbl = parents[parentIndex]
        x.lCol = commonColumns[0]
        x.rCol = commonColumns[0]


  #####################
  # QUERY DATA LOOKUP #
  #####################

  # recursively identify the path to a joined table:
  # given a database table name, return the list of join operations (query
  # object joinData) to get to the joined table from the base table
  joinPath: (tgt) ->
    if tgt == @from
      return []
    else
      j = _.findWhere( @joinData, {rTbl:tgt} )
      return if j.lTbl == @from then [ j ] else @joinPath(j.lTbl).concat( j )

  # return the metadata associated with a column in the query output:
  # given an output column name, return the metadata associated with the column
  # (query object columnData)
  columnMetadata: (col) -> _.findWhere @columnData, {displayAs:col}

  # return the list of acceptable values for a column:
  # given the name of a query output column that points to a lookup table,
  # return the acceptable values in the lookup table
  listValues: (col) ->
    columnData = @columnMetadata(col)
    @tables[ columnData.sourceTable ].pluck(columnData.sourceColumn)

  # identify the join operation path between table rows:
  # given a starting object (database row model) and either a query output
  # column name or a column reference (table.column), return the list of
  # objects that connect the starting object to the object containing the
  # output column
  objectPath: (obj, col) ->
    if col.match /\./
      joins = @joinPath col.split('.')[0]
    else
      colData = @columnMetadata(col)
      joins = @joinPath colData.sourceTable
    nextObj = (o,j) =>
      o.concat @tables[j.rTbl].lookup( j.rCol, _.last(o).get(j.lCol) )
    _.foldl joins, nextObj, [obj]

  # look up a column value given a source object:
  # given a starting object (database row model) and either a query output
  # column name or a column reference (table.column), return the output value
  # by performing any required join operations
  columnLookup: (obj, col) ->
    if col.match /\./
      lookupCol = col.split('.')[1]
    else
      lookupCol = @columnMetadata(col).sourceColumn
    _.last(@objectPath(obj,col)).get lookupCol

  # return all query result data connected to a source table row model
  getObjectData: (obj) ->
    k = _.pluck( @columnData, 'displayAs' )
    v = _.map k, (col)=>@columnLookup(obj,col)
    _.object(k,v)

  # return all data from query object: iterate over rows in source
  # table and return all linked column data
  getAllData: ->
    @tables[@from].map (obj) => @getObjectData(obj)

  # return ID values for all connected tables given a source table row model
  getIdValues: (obj) ->
    v = _.map @joinData, (x)=>@columnLookup(obj,"#{x.rTbl}.#{x.rCol}")
    _.object _.pluck(@joinData,'rTbl'), v


  ##########################
  # QUERY DATA INTERACTION #
  ##########################

  # set a value in the query given an object representing the row in the source
  # table, the corresponding query output column name, and the new value.  data
  # propagate to source tables.
  setValue: (obj, col, v) ->

    # look up metadata associated with the query output column
    columnData = @columnMetadata(col)
    throw "Invalid column: #{col}" unless columnData?

    # if the query output column comes from the source table, just set it
    if columnData.sourceTable == this.from
      Backbone.Model.prototype.set.call(obj,col,v)

    # otherwise set the pointer to reference the new value
    else
      throw "Illegal value for '#{col}': #{v}" unless _.contains(@listValues(col), v)
      lastJoin = _.last @joinPath( columnData.sourceTable )
      newId = @tables[ lastJoin.rTbl ]          # table containing new value
        .lookup( columnData.sourceColumn, v )   # identify new value in table
        .get( lastJoin.rCol )                   # get ID associated with value
      parentObj = @objectPath(obj,col)[-2..][0] # previous object in chain
      parentObj.set( lastJoin.lCol, newId )     # set value in parent

  # return true if the object matches the WHERE filter
  objectIncluded: (obj) ->
    if @where?
      v1 = @columnLookup obj, @where[0]   # value of column in table
      v2 = @where[2]                      # value in WHERE clause
      v2 = parseInt(v2) if v2[0] != "'"   # convert WHERE to numeric if applicable
      out = switch @where[1]              # perform comparison...
        when "="  then v1 == v2
        when ">"  then v1 >  v2
        when ">=" then v1 >= v2
        when "<"  then v1 <  v2
        when "<=" then v1 <= v2
        when "<>" then v1 != v2
        else false
    else
      out = true


# =============================================================================
#
# Query model
#
# =============================================================================

class QueryModel extends Backbone.Model

  # initialization
  initialize: ->
    @query = @attributes.query

  # return the source object
  obj: -> @query.tables[ @query.from ].get( @id )

  # pull data from query object for get method
  get: (x) -> @query.columnLookup(@obj(), x)

  # use query object to handle set method
  set: (a,b,opt) ->
    if _.isObject(a) and a.id? and a.query? # initial function call
      Backbone.Model.prototype.set.call(@,a,b,opt)
    else
      @query.setValue(@obj(), a, b)

  # conversion of model to JSON
  toJSON: -> @query.getObjectData(@obj())

  # get ID values for source tables
  sourceTables: -> @query.getIdValues( @obj() )


# =============================================================================
#
# Query collection
#
# =============================================================================

class QueryCollection extends Backbone.Collection
  model: QueryModel

  # initialization
  initialize: (model,query) ->

    # attach query string
    @query = query

    # set comparator (required for sort function to be triggered)
    @comparator = query.orderBy if query.orderBy?

    # add each item to collection (if included in WHERE clause)
    query.tables[query.from].each (x) =>
      @add { id: x.id, query: query } if query.objectIncluded(x)

    # listen to events in base table
    query.tables[query.from].on
      change: (m) => @trigger('change')
      add:    (m) => @add( id:m.id, query: @query )
      remove: (m) => @remove(m.id)

    # listen to events in linked tables
    _.each _.pluck(@query.joinData, 'rTbl'), (x) =>
      query.tables[x].on( 'change', => @trigger('change') )

  # sorting
  sort: (options = {}) ->
    @models = @sortBy( @comparator, @ )
    @models = @models.reverse()   if @query.sortDirection == 'DESC'
    @trigger('sort', @, options)  if !options.silent
    return @

  # conversion of data to HTML table
  toTable: -> collectionToTable(@)


# =============================================================================
#
# View for a listbox with optional parent/child relationships
#
# =============================================================================

class TableListView extends Backbone.View


  ##################
  # INITIALIZATION #
  ##################

  initialize: (@options) ->

    # add view as a child of parent view if applicable
    if @options.parent?
      @options.parent.options.children = @options.parent.options.children || []
      @options.parent.options.children.push @

    # default is to automatically select the first element
    @options.autoSelect = if @options.autoSelect? then @options.autoSelect else true

    # render view
    @render()

    # re-render on model events
    @listenTo @model, 'all', (ev) ->
      @render() if ev != 'sort'


  #############
  # RENDERING #
  #############

  # return an option value entry for a model
  opt: (x) => "<option value='#{x.id}'>#{x.get(@options.field)}</option>"

  # callback for change event
  changeCallback: (options) =>

    # re-render children lists
    if @options.children?
      for x in @options.children
        x.render @options.triggerOptions

    # update linked form data
    if @options.linkedFormData? and  @$el.val()?
      for k, v of @options.linkedFormData

        # model value to attach to linked form element
        newValue = @model.get( @$el.val() ).get(k)

        # if the element is a select, and the new value doesn't look like a
        # number, look up the index of the new value in the select list.
        # otherwise just assign it
        if v.is('select') and not _.isNumber(newValue)
          optionData = v.find('option').map( -> [[ $(@).html(), $(@).val() ]] ).toArray()
          v.val _.object(optionData)[newValue]
        else
          v.val newValue

        # attach the new value in case rendering happens out of order
        v.data('value',newValue)

        # trigger a change event
        v.trigger 'change', @options.triggerOptions

    # execute post-change callback
    @options.postChange() if @options.postChange?

    # return element
    return @

  # rendering function
  render: (triggerOptions) =>

    # capture current selection
    oldSelection = @$el.val() || @$el.data('value')

    # sorted and filtered model data
    mdl = if @model.comparator? then @model.sort() else @model
    mdl = @options.filter(mdl) if @options.filter?

    # set option value entries
    if _.isArray(mdl)
      @$el.html _.map(mdl, @opt)
    else
      @$el.html mdl.map(@opt)

    # try to set the value to the previous selection or attached value
    # if this doesn't work, store the new value in case re-rendering happened
    # out of sequence
    if @options.autoSelect
      if oldSelection?
        @$el.data('value', oldSelection).val(oldSelection)
        unless @$el.val()?
          @$el[0].selectedIndex = 0
      else
        @$el[0].selectedIndex = 0

    # bind and trigger change callback
    @$el.change @changeCallback             # bind change callback
    @$el.trigger 'change', triggerOptions   # trigger change callback

    # execute post-render callback
    @options.postRender() if @options.postRender?


  ##################
  # CLICK HANDLING #
  ##################

  # get current form data
  getFormData: ->
    out = {}
    for k, v of @options.linkedFormData
      m = @model.first()
      if _.isNumber(m.get(k))
        out[k] = parseInt( v.val() )
      else
        out[k] = v.val()
    return out

  # return number of dependencies
  nDependencies: ->
    if @options.children? and @options.children[0].options.filter?
      @options.children[0].options.filter( @options.children[0].model ).length
    else
      0

  # delete current selection (DELETE)
  deleteSelection: ->
    if @nDependencies() > 0
      window.alert 'Model has dependencies'
    else
      m = @model.get(@$el.val()).toJSON()
      if window.confirm "Confirming deletion:\n#{JSON.stringify(m)}"
        this.model.remove( @$el.val() )

  # add a new element using form data (CREATE)
  createFromSelection: (options = {}) ->
    formData = _.omit @getFormData(), @model.idAttribute
    @model.create formData, _.extend({wait:true, async:false}, options)

  # update element using form data (UPDATE)
  updateFromSelection: ->
    @model.get( @$el.val() ).set @getFormData()


# =============================================================================
#
# View for a table of sends
#
# =============================================================================

# render a table of sends
class SendView extends Backbone.View

  # ----- initialization -----
  initialize: ->

    # render view
    @render()

    # re-render on model events
    @listenTo @model, 'all', (ev) ->
      @render() if ev != 'sort'

  # ----- rendering -----
  render: =>

    # build table of sends
    @$el.html @model.toTable()
    @$el.find('table').addClass('pure-table')

    # click handler for send table
    @$el.find('table > tbody > tr').click ->
      send = sends.get $(@).attr('data-id')
      route = routes.get(send.sourceTables().routes)
      gui.sends.$date.val     send.get('Date')
      gui.sends.$route.val    send.get('Route')
      gui.sends.$climber.val  send.sourceTables().climbers
      gui.sends.$grade.val    send.sourceTables().grades
      gui.sends.$style.val    send.sourceTables().ascent_styles
      gui.sends.$area.val     route.sourceTables().areas
      gui.sends.$area.trigger 'change'
      gui.sends.$cliff.val    route.sourceTables().cliffs
      gui.sends.$send_id.val  send.id
      gui.sends.$route_id.val send.sourceTables().routes
      window.scrollTo(0,0)


# =============================================================================
#
# View for Query orphans
#
# =============================================================================

# render a table of sends
class QueryOrphans extends Backbone.View

  # ----- initialization -----
  initialize: ->

    # render view
    @render()

    # re-render on model events
    @listenTo @model, 'all', (ev) ->
      @render() if ev != 'sort'

  # ----- rendering -----
  render: =>

    # loop through query joins
    for x in @model.query.joinData

      # identify orphans
      lKeys = tables[x.lTbl].pluck(x.lCol)
      rKeys = tables[x.rTbl].pluck(x.rCol)
      parentOrphans = _.difference( lKeys, rKeys )
      childOrphans  = _.difference( rKeys, lKeys )

      # create table for left table orphans
      if parentOrphans.length > 0
        orphans = tables[x.lTbl].filter (a)->_.contains(parentOrphans,a.get(x.lCol))
        collectionToTable(orphans)
        this.$el.append "<h2>" + x.lTbl + " -> " + x.rTbl + "</h2>\n" + collectionToTable(orphans)

      # create table for right table orphans
      if childOrphans.length > 0
        orphans = tables[x.rTbl].filter (a)->_.contains(childOrphans,a.get(x.rCol))
        collectionToTable(orphans)
        this.$el.append "<h2>" + x.lTbl + " -> " + x.rTbl + "</h2>\n" + collectionToTable(orphans)

    # style tables
    @$el.find('table').addClass('pure-table')

    # return model
    return @

# =============================================================================
#
# Application
#
# =============================================================================

# wait for document to be ready and then execute code below
jQuery ->


  ###################################
  # GUI ELEMENT REFERENCE STRUCTURE #
  ###################################

  window.gui =
    sends:
      $date:          $('input#send_date')
      $style:         $('select#send_style')
      $climber:       $('select#send_climber')
      $route:         $('input#send_route')
      $routeSel:      $('select#routeSelect')
      $grade:         $('select#send_grade')
      $area:          $('select#send_area')
      $cliff:         $('select#send_cliff')
      $send_id:       $('input#send_id')
      $route_id:      $('input#send_route_id')
    areas:
      $area:          $('select#area_area')
      $cliff:         $('select#area_cliff')
      $route:         $('select#area_route')
      $area_name:     $('input#area_area_name')
      $area_location: $('input#area_area_location')
      $cliff_name:    $('input#area_cliff_name')
      $cliff_parent:  $('select#area_cliff_parent')
      $route_name:    $('input#area_route_name')
      $route_grade:   $('select#area_route_grade')
      $route_parent:  $('select#area_route_parent')
    visualization:
      $send_table:    $('div#SendTable')
      $route_orphans: $('div#RouteOrphans')
      $send_orphans:  $('div#SendOrphans')


  #################################
  # QUERY AND TABLE CONFIGURATION #
  #################################

  # load table data
  window.tables = {}
  $.ajax url:'/tableData', dataType:'json', async:false, success:(x)->
    for a in x
      $.ajax url:"/#{a.name}", dataType:'json', async:false, success:(y)->
        window.tables[ a.name ] = convertTable(y, a.name, a.id)

  # query objects
  window.sends  = new QueryCollection( null, new Query(sendQuery, tables) )
  window.routes = new QueryCollection( null, new Query(routeQuery,tables) )

  # table sort order
  tables['grades'  ].comparator = 'grade_sort'
  tables['cliffs'  ].comparator = 'cliff_name'
  tables['routes'  ].comparator = 'name'
  tables['areas'   ].comparator = 'area_name'
  tables['climbers'].comparator = 'display'


  #############################
  # FILL SEND FORM LIST BOXES #
  #############################

  # default to today for send date
  gui.sends.$date[0].valueAsDate = new Date()

  # fill climber list
  gui.sends.climberView = new TableListView
    model:  tables.climbers
    el:     gui.sends.$climber
    field:  'display'
    filter: (x) -> x.where(enabled:1)

  # fill style list
  gui.sends.styleView = new TableListView
    model:  tables.ascent_styles
    el:     gui.sends.$style
    field:  'style_name'

  # fill grade list
  gui.sends.gradeView = new TableListView
    model:  tables.grades
    el:     gui.sends.$grade
    field:  'grade'

  # fill area list
  gui.sends.areaView = new TableListView
    model:  tables.areas
    el:     gui.sends.$area
    field:  'area_name'

  # fill cliff list
  gui.sends.cliffView = new TableListView
    model:  tables.cliffs
    el:     gui.sends.$cliff
    field:  'cliff_name'
    filter: (x) -> x.where(area_id: parseInt(gui.sends.$area.val()))
    parent: gui.sends.areaView


  ######################
  # SEND DATA HANDLING #
  ######################

  # class to connect to form data without rendering
  class DummyView extends TableListView
    render: ->

  # dummy view for send data handling
  gui.sends.sendView = new DummyView
    model:  tables.ascents
    el:     gui.sends.$send_id
    linkedFormData:
      route_id:   gui.sends.$route_id
      climber_id: gui.sends.$climber
      style_id:   gui.sends.$style
      send_date:  gui.sends.$date

  # dummy view for send route data handling
  gui.sends.routeView = new DummyView
    model:  tables.routes
    el:     gui.sends.$route_id
    linkedFormData:
      name:     gui.sends.$route
      grade_id: gui.sends.$grade
      cliff_id: gui.sends.$cliff


  #############################
  # FILL AREA FORM LIST BOXES #
  #############################

  # fill grade list
  gui.areas.gradeView = new TableListView
    model:  tables.grades
    el:     gui.areas.$route_grade
    field:  'grade'

  # fill area list
  gui.areas.areaView = new TableListView
    model:    tables.areas
    el:       gui.areas.$area
    field:    'area_name'
    linkedFormData:
      area_name:  gui.areas.$area_name
      location:   gui.areas.$area_location
      area_id:    gui.areas.$cliff_parent

  # fill cliff list
  gui.areas.cliffView = new TableListView
    model:  tables.cliffs
    el:     gui.areas.$cliff
    field:  'cliff_name'
    filter: (x) -> x.where(area_id: parseInt(gui.areas.$area.val()))
    parent: gui.areas.areaView
    linkedFormData:
      cliff_name: gui.areas.$cliff_name
      cliff_id:   gui.areas.$route_parent
      area_id:    gui.areas.$cliff_parent

  # fill cliff parent list (area associated with cliff)
  gui.areas.cliffParentView = new TableListView
    model:    tables.areas
    el:       gui.areas.$cliff_parent
    field:    'area_name'
    parent:   gui.areas.areaView

  # fill route list
  gui.areas.routeView = new TableListView
    model:  tables.routes
    el:     gui.areas.$route
    field:  'name'
    filter: (x) -> x.where(cliff_id: parseInt(gui.areas.$cliff.val()))
    parent: gui.areas.cliffView
    linkedFormData:
      name:     gui.areas.$route_name
      grade_id: gui.areas.$route_grade
      cliff_id: gui.areas.$route_parent

  # add sends as dependencies of route list
  gui.areas.routeView.nDependencies = ->
    routeId = @model.get( @$el.val() ).get('route_id')
    tables.ascents.where( route_id: routeId ).length

  # fill route parent list (cliff associated with route)
  gui.areas.routeParentView = new TableListView
    model:  tables.cliffs
    el:     gui.areas.$route_parent
    field:  'cliff_name'
    filter: (x) -> x.where(area_id: parseInt(gui.areas.$area.val()))
    parent: gui.areas.cliffView


  ##################################
  # ROUTE SEARCH LISTBOX OPERATION #
  ##################################

  # create a view for routes matching search text (search results list)
  gui.sends.routeSearchView = new TableListView
    model:  routes
    el:     gui.sends.$routeSel
    field:  'Route'
    filter: (x) ->
      searchText = $('input#send_route').val().toLowerCase()
      x.filter( (x)->x.get('Route').toLowerCase().indexOf(searchText)>-1 )
    linkedFormData:
      ID:     gui.sends.$route_id
      Route:  gui.sends.$route
      Grade:  gui.sends.$grade
      Area:   gui.sends.$area
      Cliff:  gui.sends.$cliff
    autoSelect: false
    triggerOptions:     # pass ignoreChanges:true to triggered children
      ignoreChanges: true
    postChange: ->                          # when the value changes...
      gui.sends.$route_id.val $(@el).val()  # set route ID box
      gui.sends.$send_id.val  ''            # clear send ID box

  # over-ride rendering function in search results list
  gui.sends.routeSearchView.opt = (x) ->
    """<option value='#{x.id}'>
      #{x.get('Route')} (#{x.get('Grade')}, #{x.get('Area')})
     </option>"""

  # bind to keyup event in search box
  gui.sends.$route.keyup ->
    gui.sends.routeSearchView.render()
    gui.sends.$route_id.val ''

  # clear route and send ID boxes if route properties change in send form
  # unless the change was triggered from the route search result list
  gui.sends.$area           # if area dropdown changes ...
    .add gui.sends.$cliff   # or the cliff dropdown ...
    .add gui.sends.$grade   # or the grade dropdown ...
    .add gui.sends.$route   # or the route textbox ...
    .change (ev, opt) ->
      unless opt? and opt.ignoreChanges
        gui.sends.$route_id.val ''
        gui.sends.$send_id.val  ''


  ###########################################
  # NEW/UPDATE/DELETE BUTTON CLICK HANDLERS #
  ###########################################

  # click handlers for route data
  $('button#route_create').click -> gui.areas.routeView.createFromSelection()  # CREATE
  $('button#route_update').click -> gui.areas.routeView.updateFromSelection()  # UPDATE
  $('button#route_delete').click -> gui.areas.routeView.deleteSelection()      # DELETE


  # click handlers for cliff data
  $('button#cliff_create').click -> gui.areas.cliffView.createFromSelection()  # CREATE
  $('button#cliff_update').click -> gui.areas.cliffView.updateFromSelection()  # UPDATE
  $('button#cliff_delete').click -> gui.areas.cliffView.deleteSelection()      # DELETE

  # click handlers for area data
  $('button#area_create').click -> gui.areas.areaView.createFromSelection()    # CREATE
  $('button#area_update').click -> gui.areas.areaView.updateFromSelection()    # UPDATE
  $('button#area_delete').click -> gui.areas.areaView.deleteSelection()        # DELETE

  # create entry in route table from send form if it doesn't already exist
  createRouteIfNew = ->
    if gui.sends.$route_id.val() == ""
      gui.sends.$route_id.val gui.sends.routeView.createFromSelection().id

  # click handlers for send data
  $('button#send_create').click ->    # CREATE
    createRouteIfNew()
    gui.sends.$send_id.val gui.sends.sendView.createFromSelection().id
  $('button#send_update').click ->    # UPDATE
    createRouteIfNew()
    if gui.sends.$send_id.val() != ""
      gui.sends.sendView.updateFromSelection()
    else
      window.alert 'Nothing to update'
  $('button#send_delete').click ->    # DELETE
    if gui.sends.$send_id.val() != ""
      gui.sends.sendView.deleteSelection()
      gui.sends.$send_id.val  ''
    else
      window.alert 'Nothing to delete'

  ##############
  # DATA VIEWS #
  ##############

  # create view for table of sends
  gui.visualization.sendView = new SendView
    model: sends
    el:    gui.visualization.$send_table

  # create view for Route orphans
  gui.visualization.$route_orphans
    .html('<a style="color:blue; cursor:pointer">Create view</a>')
    .click ->
      $(this).html('')
      gui.visualization.routeOrphans = new QueryOrphans
        model:  routes
        el:     gui.visualization.$route_orphans

  # create view for Send orphans
  gui.visualization.$send_orphans
    .html('<a style="color:blue; cursor:pointer">Create view</a>')
    .click ->
      $(this).html('')
      gui.visualization.sendOrphans = new QueryOrphans
        model:  sends
        el:     gui.visualization.$send_orphans
