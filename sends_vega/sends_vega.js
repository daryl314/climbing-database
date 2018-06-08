// calculate some additional fields
var now = new Date();
var minYear = now.getFullYear();
var foundGrades = {};
var gradeSort = [];
data.forEach(x => {
  x.SendDate = new Date(x.SendDate);
  x.Year = x.SendDate.getFullYear();
  x.Years = Math.floor((now - x.SendDate) / 1000 / 60 / 60 / 24 / 365.25);
  x.Grade = x.Grade.slice(0,5);
  minYear = x.Year < minYear ? x.Year : minYear;
  if (!foundGrades[x.Grade]) {
    foundGrades[x.Grade] = x.GradeSort;
    gradeSort.push(x.Grade);
  }
});

// create pivot table
var pivot = [];
for (let y = minYear; y <= now.getFullYear(); y++) {
  let pivotRow = {};
  gradeSort.forEach(g => {
    pivotRow[g] = 0;
  })
  pivot.push(pivotRow);
}
data.forEach(x => {
  let i = x.Year - minYear;
  pivot[i][x.Grade] += 1;
});

// stack data
var stacked = [];
for (let i = 0; i < pivot.length; i++) {
  let year = minYear + i;
  let row = pivot[i];
  gradeSort.forEach(g => {
    stacked.push({
      Year: year,
      Grade: g,
      GradeSort: foundGrades[g],
      Sends: row[g]
    });
  });
};

// filter stacked data
let ry = stacked.filter(x => x.GradeSort >= 512);
let by = stacked.filter(x => x.GradeSort >= 6 && x.GradeSort < 20);

// minimum grade to show
let minBoulder = 6;  // V6
let minRoute = 512;  // 5.12

function areaChart(data, colorMap="category20") {
  return {

    // vega 3 chart...
    "$schema": "https://vega.github.io/schema/vega/v3.json",
    "width": 600,
    "height": 300,
    "padding": 5,
    "description": "Stacked area chart of sends over time",
    "title": "Sends over time",

    // define input data: function input as "table"
    "data": [{
      "name": "table",
      "values": data,

      // stack data grouped by Year and sorted by GradeSort
      "transform": [{
        "type": "stack",
        "groupby": ["Year"],
        "sort": {"field": "GradeSort", "order": "descending"},
        "field": "Sends",
        "as": ["y0","y1"] // computed output fields (defaults to y0,y1)
      }]
    }],

    // define mappings from data values to visual values (pixels, colors, sizes)
    "scales": [
      { // x values come from 'Year' column in 'table'
        "name": "x",
        "type": "point",
        "range": "width",
        "domain": {"data": "table", "field": "Year"}
      }, { // y values come from high-side computed stack
        "name": "y",
        "type": "linear",
        "range": "height",
        "nice": true,  // extend domain to end on nice round numbers
        "zero": true,  // include zero in the domain
        "domain": {"data": "table", "field": "y1"}
      }, { // define a color map for data
        "name": "color", 
        "type": "ordinal", 
        "range": {"scheme": colorMap}
      }, { // define legend labels that correspond to color map
        "name": "legend_labels",
        "type": "ordinal",
        "range": {"scheme": colorMap},
        // sort order for legend labels
        "domain": data.filter(x => x.Year == data[0].Year).map(x => x.Grade)
      }
    ],

    // define axes
    "axes": [{
        "orient": "bottom",
        "scale": "x",
        "zindex": 0,
        "title": "Year",
        "grid": true
      },{
        "orient": "left",
        "scale": "y",
        "zindex": 0,
        "title": "Sends",
        "grid": true
      }
    ],

    // define visual encoding
    "marks": [{
      "type": "group",
      "from": {"facet": {"name": "series", "data": "table", "groupby": "GradeSort"}},

      // define 'area' encoding
      "marks": [{
        "type": "area",
        "from": {"data": "series"},

        // properties of the area chart
        "encode": {

          // area mark properties applied when the marks are created
          "enter": {
            "x": {"scale": "x", "field": "Year"},
            "y": {"scale": "y", "field": "y0"},
            "y2": {"scale": "y", "field": "y1"},
          },

          // area mark properties applied when updates happen (or when hover exits)
          "update": {
            "fillOpacity": {"value": 1},
            "fill":{"scale":"color","field":"GradeSort"}
          },

          // area mark properties applied on hover
          "hover": {
            "fill":{"value":"black"},
            "fillOpacity": {"value": 0.5}
          }
        }
      }]
    }],

    // define a legend using the custom labels
    "legends": [{
      "fill": "legend_labels",
      "title": "Grade",
      "encode": {
        "labels": {
          "update": {
            "fontSize": {"value": 16}, 
            "fill": {"value": "black"}}
        }
      }
    }]
  }
}

var vlSpec2 = {

  // vega 3 chart...
  "$schema": "https://vega.github.io/schema/vega/v3.0.json",
  "padding": 5,
  "width": 500,
  "height": 300,
  "description": "Climbing sends bar chart",
  "title": "Distribution of sends",

  // define data
  "data": [

    {  // attach data to source_0 data sourc
      "name": "source_0",
      "values": data
    },
    
    { // compute data_0 based on source_0...
      "name": "data_0",
      "source": "source_0",
      "transform": [

        { // bucket by year clipped at 5 years
          "type": "formula",
          "expr": "datum.Years > 4 ? 5 : datum.Years",
          "as": "YearBucket"
        },

        { // filter out data below minimum grade
          "type": "filter", 
          "expr": `inrange(datum["GradeSort"], [${minBoulder}, 15]) || inrange(datum["GradeSort"], [${minRoute},515])`
        },
        
        { // agggregate data by YearBucket
          "type": "aggregate",
          "groupby": ["Grade", "YearBucket"],
          "ops": ["count"],
          "fields": ["*"],
          "as": ["count_*"]
        },
        
        { // create a stacking series based on aggregation
          "type": "stack",
          "groupby": ["Grade"],
          "field": "count_*",
          "sort": {"field": ["YearBucket"], "order": ["ascending"]},
          "as": ["count_*_start", "count_*_end"],
          "offset": "zero"
        }
      ]
    }
  ],

  // define bar data
  "marks": [{
    "name": "marks",
    "type": "rect",
    "style": ["bar"],
    "from": {"data": "data_0"},
    "encode": {
      "update": {
        "fill": {"scale": "color", "field": "YearBucket"},
        "tooltip": {"signal": "''+datum[\"Grade\"]"},
        "x": {"scale": "x", "field": "Grade"},
        "width": {"scale": "x", "band": true},
        "y": {"scale": "y", "field": "count_*_end"},
        "y2": {"scale": "y", "field": "count_*_start"}
      }
    }
  }],

  // define mappings from data values to visual values (pixels, colors, sizes)
  "scales": [{
      "name": "x",
      "type": "band",
      "domain": {"data": "data_0", "field": "Grade"},
      "range": [0, {"signal": "width"}],
      "paddingInner": 0.1,
      "paddingOuter": 0.05
    },{
      "name": "y",
      "type": "linear",
      "domain": {"data": "data_0", "fields": ["count_*_start", "count_*_end"]},
      "range": [{"signal": "height"}, 0],
      "nice": true,
      "zero": true
    },{ // color map for data
      "name": "color",
      "type": "ordinal",
      "domain": [0,1,2,3,4,5],
      "range": {"scheme": "yelloworangebrown-6"},
      "reverse": true
    },{ // custom legend labels matching data color map
      "name": "legend_labels",
      "type": "ordinal",
      "range": {"scheme": "yelloworangebrown-6"},
      "domain": ["0 Years","1 Year","2 Years","3 Years","4 Years","5+ Years"],
      "reverse": true
    }
  ],

  // define axes
  "axes": [{
    "scale": "x",
    "orient": "bottom",
    "title": "Grade",
    "labelOverlap": true,
    "encode": {
      "labels": {
        "update": {
          "angle": {"value": 270},
          "align": {"value": "right"},
          "baseline": {"value": "middle"}
        }
      }
    },
    "zindex": 1
  },{
    "scale": "y",
    "orient": "left",
    "title": "Number of Sends",
    "labelOverlap": true,
    "tickCount": {"signal": "ceil(height/40)"},
    "zindex": 1
  },{
    "scale": "y",
    "orient": "left",
    "grid": true,
    "tickCount": {"signal": "ceil(height/40)"},
    "gridScale": "x",
    "domain": false,
    "labels": false,
    "maxExtent": 0,
    "minExtent": 0,
    "ticks": false,
    "zindex": 0
  }],

  // define legend using custom labels
  "legends": [{
    "fill": "legend_labels",
    "encode": {"symbols": {"update": {"shape": {"value": "square"}}}}
  }],

  // min y axis range
  "config": {"axisY": {"minExtent": 30}}
};

  // Embed the visualization in the container with id `vis`
  let vega_options = {
    actions: {
      export   : true,
      source   : false,
      compiled : false,
      editor   : true
    }
  };
  vegaEmbed("#chartContainer", vlSpec2                     , vega_options);
  vegaEmbed("#routeArea"     , areaChart(ry, "category20b"), vega_options);
  vegaEmbed("#boulderArea"   , areaChart(by)               , vega_options);

  ///////////////////////////////

  // best sends 
  let sortedSends = _.orderBy(data, ['GradeSort','SendDate'], ['desc','desc']);
  let bestSends = {
    'routeRedpoint'   : sortedSends.find(x => x.Style == 'redpoint' && x.GradeSort >= 500),
    'routeFlash'      : sortedSends.find(x => x.Style == 'flash'    && x.GradeSort >= 500),
    'routeOnsight'    : sortedSends.find(x => x.Style == 'onsight'  && x.GradeSort >= 500),
    'boulderRedpoint' : sortedSends.find(x => x.Style == 'redpoint' && x.GradeSort <  500),
    'boulderFlash'    : sortedSends.find(x => x.Style == 'flash'    && x.GradeSort <  500)
  };
  $('#best_sends').html(`
    <li>Route Redpoint: ${bestSends.routeRedpoint.Route} (${bestSends.routeRedpoint.Grade})</li>
    <li>Route Flash: ${bestSends.routeFlash.Route} (${bestSends.routeFlash.Grade})</li>
    <li>Route Onsight: ${bestSends.routeOnsight.Route} (${bestSends.routeOnsight.Grade})</li>
    <li>Boulder Redpoint: ${bestSends.boulderRedpoint.Route} (${bestSends.boulderRedpoint.Grade})</li>
    <li>Boulder Flash: ${bestSends.boulderFlash.Route} (${bestSends.boulderFlash.Grade})</li>
  `);

  // most recent sends
  let sendsByDate = _.orderBy(data, ['SendDate'], ['desc']);
  $('ul#recent_sends').html(
    sendsByDate.slice(0,5).map(x => 
      `<li>${x.Route} (${x.Grade}) ${x.Style.slice(0,1).toUpperCase()}${x.Style.slice(1)} ${x.SendDate.toLocaleDateString()}</li>`
    ).join('\n')
  );

  // selector
  $('select#minBoulder').html( gradeSort.filter(x => x.startsWith('V' )).map(x => `<option value=${foundGrades[x]}>${x}</option>`).join('\n'))
  $('select#minRoute'  ).html( gradeSort.filter(x => x.startsWith('5.')).map(x => `<option value=${foundGrades[x]}>${x}</option>`).join('\n'))
  console.log($('select#minBoulder').val());

  // table of sends
  function sendTable(title, data) {
    let tr = data.map(x => `
      <tr class='sends'>
        <td>${x.Grade}</td>
        <td><span title='${x.Area}'>${x.Route}</span></td>
        <td class='${x.Style}'>${x.SendDate.toLocaleDateString()}</td>
      </tr>
    `);
    return tr.join('\n')
  }
  $('table#all_routes'  ).html(sendTable('Routes',           _.filter(sendsByDate, x => x.GradeSort > minRoute                       )));
  $('table#all_boulders').html(sendTable('Boulder Problems', _.filter(sendsByDate, x => x.GradeSort > minBoulder && x.GradeSort < 500)));

  // tree of sends by area
  function objMap(o, fn) {
    return Object.keys(o).sort().map(k => fn(k, o[k]))
  }
  $('ul#sendTree').html(
    objMap(_.groupBy(data,'Area'), (area,areaData) => {
      let areaList = objMap(_.groupBy(areaData, 'Cliff'), (cliff,cliffData) => {
        let cliffList = _.sortBy(cliffData,'Route').map(x => `<li class='climb'>${x.Route} (${x.Grade})</li>`).join('\n');
        return `<li class='cliff'>${cliff}<ul style='display:none'>${cliffList}</ul></li>`
      }).join('\n');
      return `<li class='area'>${area}<ul style='display:none'>${areaList}</ul></li>`
    }).join('\n')
  );

  $('ul.tree li.area' ).on('click', function(event){$(this).children().toggle(); event.stopPropagation()});
  $('ul.tree li.cliff').on('click', function(event){$(this).children().toggle(); event.stopPropagation()});
