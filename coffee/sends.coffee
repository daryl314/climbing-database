# wait for document to be ready before doing anything
jQuery ->

  # ----------------------------------------------------------------------
  #
  # General-purpose utility functions
  #
  # ----------------------------------------------------------------------

  # Reference to root object and jquery function object
  root = global ? window
  fn = root.$.fn

  # Function to calculate the difference between two dates
  root.dateDelta=(date1,date2)->(Date.parse(date2)-Date.parse(date1))/60000/60/24/365

  # Add a function to capitalize words to underscore
  _.capitalize = (str) -> str[0].toUpperCase() + str[1..].toLowerCase()

  # ----------------------------------------------------------------------
  #
  # Climbing-specific utility functions
  #
  # ----------------------------------------------------------------------

  # Function to trim zeroes from grades
  root.trimZeroes = (txt) -> txt.replace('V0','V').replace('5.0','5.')

  # Function to round slash grades
  root.roundGrade = (x) ->
    if      x < 10  then "V0#{Math.floor(x)}"
    else if x < 20  then "V#{Math.floor(x)}"
    else if x < 510 then "5.0#{Math.floor(x-500)}"
    else
      base = Math.floor(x) - 500
      remainder = Math.round(100*(x - Math.floor(x)))
      if      remainder < 20 then letter = 'a'
      else if remainder < 30 then letter = 'b'
      else if remainder < 40 then letter = 'c'
      else letter = 'd'
      "5.#{base}#{letter}"

  # ----------------------------------------------------------------------
  #
  # Parse input data
  #
  # ----------------------------------------------------------------------

  # Load data from ajax request if not already loaded
  unless root.data?
    $.ajax
      url:      '/Sends'
      success:  (x) -> root.data = x
      async:    false

  # Calculate year and grade buckets
  root.processedData = _.map root.data, (x) ->
    x.YearBucket  = Math.floor dateDelta(x.SendDate, Date())
    x.GradeBucket = roundGrade x.GradeSort
    x

  # Unique route and boulder grades
  uniqueGrades = _.chain(processedData).pluck('GradeBucket').unique().sort().value()
  uniqueBoulder = $.grep(uniqueGrades, (x) -> x[0] == 'V' )
  uniqueRoute   = $.grep(uniqueGrades, (x) -> x[0] != 'V' )
  unique = { grades:uniqueGrades, boulder:uniqueBoulder, route:uniqueRoute }

  # Function to return filtered data based on thresholds
  filteredData = ->
    minRoute   = $.inArray($('#route_value').data('value'),unique.route)
    minBoulder = $.inArray($('#boulder_value').data('value'),unique.boulder)
    $.grep(data, (x)-> $.inArray(x.GradeBucket,unique.route)>=minRoute ||
      $.inArray(x.GradeBucket,unique.boulder)>=minBoulder)

  # ----------------------------------------------------------------------
  #
  # Function to refresh plot
  #
  # ----------------------------------------------------------------------

  # Color options
  plotColors = {
    default: ["#3366cc","#dc3912","#ff9900","#109618","#990099","#0099c6"],
    defaultWithBlack: ["#000000","#3366cc","#dc3912","#ff9900","#109618","#990099"],
    hot: ["#000000","#7f0000","#ff0000","#ff7f00","#ffff00","#ffff7f","#ffffff"]
  }

  # Bucket labels for bar chart
  bucketLabels = ['0 Years','1 Year','2 Years','3 Years','4 Years','5+ Years']

  # Plot options for bar charts
  barPlotOptions =
    backgroundcolor:
      stroke: 'black'
      strokewidth: 5
      fill: '#e0e0e0'
    colors: plotColors.hot
    title: 'Sends by Year'
    titleTextStyle:
      fontSize: 30
    isStacked: true
    hAxis:
      maxAlternation: 1
      slantedTextAngle: 45
    vAxis:
      gridlines:
        color: 'gray'

  # Function to refresh bar chart
  refreshBarChart = ->

    # Initialize bucket array
    sortedBuckets = _.uniq($.map(filteredData(),(x)->x.GradeBucket)).sort()
    bucketData = $.map(sortedBuckets, (x)->[[x,0,0,0,0,0,0]])

    # Gather data in buckets
    for row in filteredData()
      yearBucket = if row.YearBucket > 5 then 5 else row.YearBucket
      bucketRow = $.inArray(row.GradeBucket, $.map(bucketData, (x)->x[0]))
      bucketData[bucketRow][yearBucket+1] += 1

    # Remove leading zeroes
    bucketData = ([ trimZeroes(x[0]) ].concat(x[1..]) for x in bucketData)

    # Create data table
    dt = new google.visualization.DataTable()
    dt.addColumn('string','Grade')
    dt.addColumn('number',x) for x in bucketLabels
    dt.addRows bucketData

    # Generate plot
    new google.visualization.ColumnChart(document.getElementById('chartContainer'))
      .draw(dt,barPlotOptions)

  # Plot options for area charts
  areaPlotOptions =
    backgroundcolor:
      stroke: 'black'
      strokewidth: 5
      fill: '#e0e0e0'
    title: 'Sends by Year'
    titleTextStyle:
      fontSize: 30
    isStacked: true
    hAxis:
      maxAlternation: 1
      slantedTextAngle: 45
    vAxis:
      gridlines:
        color: 'gray'

  # Function to refresh area charts
  refreshAreaCharts = ->

    # List of years
    yearList = _.map filteredData(),(x)->x.SendDate[0..3]
    uniqueYearList = _.uniq(yearList).sort()

    # List of grades without trailing route letters
    gradeList = _.map filteredData(),(x)->x.GradeBucket[0..3]
    uniqueBoulderGrades = _.uniq(_.filter(gradeList, (x)->x[0]=='V')).sort().reverse()
    uniqueRouteGrades   = _.uniq(_.filter(gradeList, (x)->x[0]!='V')).sort().reverse()

    # Function to calculate the number of sends at a grade/year combo
    combo = _.zip(yearList, gradeList)
    sendCount = (grade,year) ->
      _.filter(combo, (x)->x[0] == year && x[1] == grade).length

    # Create data arrays for charts
    routeData = _.map(uniqueYearList,(year)->
      [year].concat(_.map(uniqueRouteGrades, (grade)->sendCount(grade,year))))
    boulderData = _.map(uniqueYearList,(year)->
      [year].concat(_.map(uniqueBoulderGrades, (grade)->sendCount(grade,year))))

    # Create bouldering data table
    dtb = new google.visualization.DataTable()
    dtb.addColumn('string','Year')
    dtb.addColumn('number',x) for x in uniqueBoulderGrades
    dtb.addRows boulderData

    # Create route data table
    dtr = new google.visualization.DataTable()
    dtr.addColumn('string','Year')
    dtr.addColumn('number',x) for x in uniqueRouteGrades
    dtr.addRows routeData

    # Create graphs
    new google.visualization.AreaChart(document.getElementById('routeArea'))
      .draw(dtr,areaPlotOptions)
    new google.visualization.AreaChart(document.getElementById('boulderArea'))
      .draw(dtb,areaPlotOptions)

  # ----------------------------------------------------------------------
  #
  # Function to refresh HTML content
  #
  # ----------------------------------------------------------------------

  # Function to convert a send to a table row
  sendToRow = (x) -> [
    "  <tr class='sends'>",
    "    <td>#{x.Grade}</td>",
    "    <td><span title='#{x.Area}'>#{x.Route}</span></td>",
    "    <td class='#{x.Style}'>#{x.SendDate}</td>",
    "  </tr>"
  ].join("\n")

  # Function to convert an array of sends into a table
  sendsToTable = (x) -> "<table>\n#{$.map(x, sendToRow).join("\n")}\n</table>"

  # Function to refresh content
  refreshContent = ->

    # Get list of best sends
    [ rp, fl, os ] = [ 'redpoint', 'flash', 'onsight' ]
    best = (style,prefix) -> $.grep(
      _.sortBy(data,(x)->x.GradeSort).reverse(),
      (x) -> x.Style==style && x.Grade[0]==prefix
    )[0]
    bestSends = [ best(rp,'5'), best(fl,'5'), best(os,'5'), best(rp,'V'), best(fl,'V') ]

    # Build HTML output for best sends
    $('#best_sends').html $.map(bestSends, (x) ->
      rb = if x.Grade[0] == '5' then 'Route' else 'Boulder'
      "#{rb} #{_.capitalize x.Style}: #{x.Route} (#{x.Grade})<br>\n"
    ).join('')

    # Build HTML content for most recent sends
    $('#recent_sends').html $.map(_.sortBy(data,(x)->x.SendDate).reverse()[0...5], (x)->
      "#{x.Route} (#{x.Grade}) #{_.capitalize x.Style} #{x.SendDate}<br>\n"
    ).join('')

    # Build HTML content for send tables
    $('#route_sends'  ).html sendsToTable($.grep(filteredData(), (x)->x.Grade[0]=='5'))
    $('#boulder_sends').html sendsToTable($.grep(filteredData(), (x)->x.Grade[0]=='V'))

  # ----------------------------------------------------------------------
  #
  # Function to build tree of sends by area and cliff
  #
  # ----------------------------------------------------------------------

  buildTree = ->
    html = "<ul class='tree'>\n"
    areaList = _.chain(processedData).pluck('Area').unique().value().sort()
    _.each areaList, (area) ->
        html = html.concat("  <li class='area'>#{area}<ul style='display:none'>\n")
        cragList = _.chain(processedData)
            .filter( (x) -> x.Area == area )
            .pluck( 'Cliff' )
            .unique()
            .value()
            .sort()
        _.each cragList, (crag) ->
            html = html.concat("    <li class='cliff'>#{crag}\n    <ul style='display:none'>\n")
            sendList = _.chain(processedData)
                .filter( (x) -> x.Area == area && x.Cliff == crag )
                .map( (x) -> "      <li class='climb'>#{x.Route} (#{x.Grade})" )
                .value()
                .join("\n")
                .concat("\n    </ul>\n")
            html = html.concat(sendList)
        html = html.concat("  </ul>\n")
    html = html.concat("</ul>")
    $('#sends_by_area').html html

  # ----------------------------------------------------------------------
  #
  # Set everything in motion
  #
  # ----------------------------------------------------------------------

  # Initialize grades
  $('#route_value').data('value','5.12a').text('5.12a')
  $('#boulder_value').data('value','V06').text('V6')

  # Create plot and content from default grade thresholds
  doRefresh = ->
    refreshBarChart()
    refreshContent()
    refreshAreaCharts()
  doRefresh()
  buildTree()

  # Create a slider for unique route grades
  $('#route_slider').slider
    value: $.inArray($('#route_value').data('value'),uniqueRoute)
    max: uniqueRoute.length-1
    stop: -> doRefresh()
    slide: (event,info) ->
      grade = uniqueRoute[info.value]
      $('#route_value').data('value',grade).text(trimZeroes(grade))

  # Create a slider for unique boulder grades
  $('#boulder_slider').slider
    value: $.inArray($('#boulder_value').data('value'),uniqueBoulder)
    max: uniqueBoulder.length-1
    stop: -> doRefresh()
    slide: (event,info) ->
      grade = uniqueBoulder[info.value]
      $('#boulder_value').data('value',grade).text(trimZeroes(grade))

  # Move sliders and buttons
  $('#route_slider'  ).position({my:'left center',at:'right center',of:'#route_value',  offset:'12 0'})
  $('#boulder_value' ).position({my:'left center',at:'right center',of:'#route_slider', offset:'25 0'})
  $('#boulder_slider').position({my:'left center',at:'right center',of:'#boulder_value',offset:'12 0'})

  # Configure send list by area interactivity
  $('li.area' ).click( (event) -> $(this).children().toggle(); event.stopPropagation()  )
  $('li.cliff').click( (event) -> $(this).children().toggle(); event.stopPropagation()  )
