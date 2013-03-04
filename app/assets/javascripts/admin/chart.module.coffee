Controller = require('controller')
moment     = require('moment')
$          = jQuery

class Chart extends Controller
  fetch: =>
    url  = "/admin/experiments/#{@options.model.id}/chart"
    $.getJSON(url, @options.params, @render)

  render: (variants) =>
    @$el.empty()

    margin = {top: 30, right: 30, bottom: 30, left: 30}
    width  = @$el.width() - margin.left - margin.right
    height = 300 - margin.top - margin.bottom

    x = d3.time.scale()
        .range([0, width])

    y = d3.scale.linear()
        .range([height, 0])

    xAxis = d3.svg.axis()
        .scale(x)
        .tickSize(1)
        .tickPadding(12)
        .ticks(d3.time.days.utc, 2)
        .orient('bottom')
        .tickFormat((d, i) -> moment(d).format('MMM Do'))

    yAxis = d3.svg.axis()
        .scale(y)
        .ticks(5)
        .tickPadding(5)
        .orient('left')

    line = d3.svg.line()
        .x((d) -> x(new Date(d.time)))
        .y((d) -> y(d.rate))

    area = d3.svg.area()
        .x((d) -> x(new Date(d.time)))
        .y0(height)
        .y1((d) -> y(d.rate))

    svg = d3.select(@$el[0]).append('svg')
        .attr('width', width + margin.left + margin.right)
        .attr('height', height + margin.top + margin.bottom)
        .append('g')
        .attr('transform', "translate(#{margin.left},#{margin.top})")

    x.domain([
      d3.min(variants, (c) -> d3.min(c.values, (v) -> new Date(v.time))),
      d3.max(variants, (c) -> d3.max(c.values, (v) -> new Date(v.time)))
    ])

    y.domain([
      d3.min(variants, (c) -> d3.min(c.values, (v) -> v.rate)),
      d3.max(variants, (c) -> d3.max(c.values, (v) -> v.rate))
    ])

    svg.append('g')
       .attr('class', 'x axis')
       .attr('transform', "translate(0,#{height})")
       .call(xAxis)

    svg.append('g')
        .attr('class', 'y axis')
        .call(yAxis)

    svg.selectAll('.areas')
        .data(variants)
        .enter().append('path')
        .attr('class', (d, i) -> "areas area-#{i}")
        .attr('d', (d) -> area(d.values))

    svgVariant = svg.selectAll('.variants')
        .data(variants)
        .enter().append('g')
        .attr('class', (d, i) -> "variants variant-#{i}")

    svgVariant.append('path')
        .attr('class', 'line')
        .attr('d', (d) -> line(d.values))

    svgVariant.selectAll('circle')
        .data((d) -> d.values)
        .enter()
        .append('circle')
        .attr('class', (d, i) -> "circle circle-#{i}")
        .attr('cx', (d, i) -> x(new Date(d.time)))
        .attr('cy', (d, i) -> y(d.rate))
        .attr('r', 4)

    # Legend

    $legend = $('<ul />').addClass('legend')
    @$el.append($legend)

    for variant, i in variants
      $variant = $('<li />').text(variant.name)
      $variant.addClass("legend-#{i}")
      $legend.append($variant)

module.exports = Chart