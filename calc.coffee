default_input_txt = "--"

# Dates and plans should be the only things that need to be updated between
# semesters

plans = [
  [ 0,   1629 ],
  [ 50,  1225 ],
  [ 105, 745  ],
  [ 135, 523  ],
  [ 165, 302  ],
  [ 210, 110  ],
  [ 285, 55   ]
]

dates =
  start: "Sep 2, 2013"
  end: "Dec 14, 2012"
  breaks:
    "Fall": [ "Oct 18, 2012", "Oct 23, 2012" ],
    "Thanksgiving": [ "Nov 26, 2012", "Dec 2, 2012" ],

american_date = (s, sep) ->
  sep = sep || "-"
  d = (new Date(Date.parse(s)))
  parts = d.toISOString().split("T")[0].split("-")
  (if parts[1][0] == "0" then parts[1].slice(1) else parts[1]) + sep +
    parts[2] + sep +
    parts[0]

d_diff = (start, end) ->
  one_day = 1000 * 60 * 60 * 24

  date_ints = _.map(dates.breaks, (a) -> _.map(a, (s) -> Date.parse(s)))
  exclude = _.reduce( date_ints, ((m, i) ->
    a = start
    b = end
    x = i[0]
    y = i[1]
    if a < x
      if b < x
        0
      else if b < y
        b - x
      else
        y - x
    else if a < y
      if b < y
        b - a
      else
        y - a
    else
      0
    ), 0 )
  total = end - start

  Math.ceil (total - exclude) / one_day

round_to = (n, p) ->
  mult = Math.pow 10, p
  Math.round(n * mult) / mult

now = Date.now()
d_total = d_diff Date.parse(dates.start), Date.parse(dates.end)
w_total = d_total / 7
d_left = d_diff now, Date.parse(dates.end)
w_left = d_left / 7
d_so_far = d_total - d_left
w_so_far = w_total - w_left

# console.log "Days left: " + d_left
# console.log "Weeks left: " + w_left
# console.log "Days so far: " + d_so_far
# console.log "Weeks so far: " + w_so_far

# Get selector for the results rows
row_sel = (row_name, subelem) ->
  switch row_name
    when "left" then "#left input"
    when "left-pd" then "#left-pd input"
    when "left-pw" then "#left-pw input"
    when "used" then "#used input"
    when "used-pd" then "#used-pd input"
    when "used-pw" then "#used-pw input"
    else ""

get_row = (n) ->
  sel = row_sel n
  _.map [ $(sel).first().val(), $(sel).last().val() ], (s) -> parseInt(s)

set_row = (n, vals, ideals) ->
  $(row_sel n).first().val if isNaN(vals[0]) then "" else round_to(vals[0], 1)
  $(row_sel n).last().val if isNaN(vals[1]) then "" else round_to(vals[1], 2)

populate_with_left = (plan) ->
  left = get_row "left"
  set_row "left-pd", _.map(left, (n) -> n / d_left)
  set_row "left-pw", _.map(left, (n) -> n / w_left)

  used = [ plan[0] - left[0], plan[1] - left[1] ]
  set_row "used", used
  set_row "used-pd", _.map(used, (n) -> n / d_so_far)
  set_row "used-pw", _.map(used, (n) -> n / w_so_far)

  # display ideal info on hover only if there aren't any errors

  m_err = $(".primary .error-m")
  p_err = $(".primary .error-p")
  m_p_err = $(".primary .error-m-p")

  # display ideal meals
  # if _.all(m_p_err, (e) -> $(e).is(":hidden")) and _.all(m_err, (e) ->
  # $(e).is(":hidden"))
  if valid_meals()
    $("tr.secondary td.m").hover(
      () -> $(this).parent().find(".ideal-m").show(),
      () -> $(this).parent().find(".ideal-m").hide()
    )
  else
    $("tr.secondary td.m").unbind "mouseenter mouseleave"
    $(".ideal-m").hide()

  # display ideal points
  # if _.all(m_p_err, (e) -> $(e).is(":hidden")) and _.all(p_err, (e) ->
  # $(e).is(":hidden"))
  if valid_points()
    $("tr.secondary td.p").hover(
      () -> $(this).parent().find(".ideal-p").show(),
      () -> $(this).parent().find(".ideal-p").hide()
    )
  else
    $("tr.secondary td.p").unbind "mouseenter mouseleave"
    $(".ideal-p").hide()

# Notice that this differs form the validity checking in `generate_errors`
# because we don't generate errors for "" or default_input_txt, but we
# don't consider them valid either.
valid_meals = ->
  _.all $("tr.primary"), (row) ->
    val = $(row).find("td.m input").val()
    !isNaN(val) and parseInt(val) > 0 and parseInt(val) < plan[0]

# Notice that this differs form the validity checking in `generate_errors`
# because we don't generate errors for "" or default_input_txt, but we
# don't consider them valid either.
valid_points = ->
  _.all $("tr.primary"), (row) ->
    val = $(row).find("td.p input").val()
    !isNaN(val) and parseInt(val) > 0 and parseInt(val) < plan[1]


generate_errors = ->
  _.each $("tr.primary"), (row) ->
    m_val = $(row).find("td.m input").val()
    p_val = $(row).find("td.p input").val()
    m = m_val != "" and m_val != default_input_txt and
      (isNaN(m_val) or parseInt(m_val) < 0 or parseInt(m_val) > plan[0])
    p = p_val != "" and p_val != default_input_txt and
      (isNaN(p_val) or parseInt(p_val) < 0 or parseInt(p_val) > plan[1])

    if m and p
      show = ".error-m-p"
      hide = [".error-m", ".error-p"]
    else if m
      show = ".error-m"
      hide = [".error-m-p", ".error-p"]
    else if p
      show = ".error-p"
      hide = [".error-m-p", ".error-m"]
    else
      show = ""
      hide = [".error-m", ".error-p", ".error-m-p"]

    $(row).find(show).show()
    $(row).find(hide.join ", ").hide()

plan = []


$(document).ready ->

  # insert the plan options into the table.
  # we reverse the plans so they get inserted in the right order.
  plans.reverse()
  # insert each plan.
  _.each plans, (p, i) ->
    row = $("<tr class='choices highlight' id='plan#{plans.length-i-1}'></tr>").prependTo "table#plans tbody"
    _.each [
      $("<td class='results title'>Total</td>"),
      $("<td>#{p[0]}</td>").addClass("m"),
      $("<td>#{p[1]}</td>").addClass("p")
    ], (cell) ->
      cell.appendTo row
  # reverse the plans back so we don't cause any unexpecetd behavior.
  plans.reverse()

  # display some preliminary info.
  $("#date").text (new Date).toDateString()
  $("#days-left").text "#{d_left} / #{d_total}"

  $("#info-target").hover(
    () -> $("#info").show(),
    () -> $("#info").hide()
  )

  # FIXME FILL IN WITH ACTUAL INFO
  info_text = "<p>I'm assuming:</p>
  <ul>
    <li>you arrived on #{american_date dates.start}</li>
    <li>you're leaving on #{american_date dates.end}</li>
  </ul>
  <p>These are the official housing open/close dates. Left-per-x
  calculations are accurate if you arrived earlier (ahem, seniors), but
  will be (very, very) slighly below their true values if you're planning to
  leave early or above if you're planning to leave later.</p>
  <p>I'm also not counting the days during these breaks:</p>
  <ul>"
  _.each(dates.breaks, (bdates, bname) ->
    info_text += "<li>#{bname}: #{american_date bdates[0]} &ndash;
  #{american_date bdates[1]}</li>"
  )
  info_text += "</ul>"

  $("#info #content").html info_text



  # we'll work on allowing input for the secondary elements later.
  # FIXME NO WE WON'T
  $(".secondary input").attr("disabled", true)

  $("tr.choices td").click ->
    $("#help-text").hide()
    $row = $(this).parent("tr")
    row = $row.get(0)
    if $row.hasClass "highlight"
      $("tr.choices.highlight").removeClass "highlight"
      $row.addClass "totalRow"
      plan = plans[row.id.split("plan")[1]]

      # hide all the other rows
      $("tr.choices").filter( -> this != row).hide()

      # show various stuff
      $(".results").show()
      $row.append back_cell

      ideal_left = _.map(plan, (n) -> n * d_left / d_total)
      ideal_used = _.map(plan, (n) -> n * d_so_far / d_total)
      ideal_pd = _.map(plan, (n) -> n / d_total)
      ideal_pw = _.map(plan, (n) -> n / w_total)

       # fill in the ideal information
      _.each ["left", "left-pd", "left-pw", "used", "used-pd", "used-pw"], (n) ->
        _.each ["m", "p"], (x) ->
          ideals = switch n
            when "left" then ideal_left
            when "used" then ideal_used
            when "left-pd", "used-pd" then ideal_pd
            when "left-pw", "used-pw" then ideal_pw
          pos = switch x
            when "m" then 0
            when "p" then 1
          round = switch x
            when "m" then 1
            when "p" then 2
          $("##{n} .ideal-#{x} .ideal-num").text round_to(ideals[pos], round)


  $("#back").click ->
    $("#help-text").show()
    back_cell.detach()
    $("tr.choices").removeClass("totalRow").addClass("highlight")
    $(".results").hide()
    $("tr.choices").show()
    $(row_sel "left").val(default_input_txt)
    $(".primary input").keyup()
    $("#plans td.error").text("")

  back_cell = $("#back-cell").detach()

  $(".primary input").val default_input_txt

  $(".primary input").keyup ->
    generate_errors()
    populate_with_left plan

  $(".primary input").focus ->
    $(this).val("") if $(this).val() == default_input_txt

  $(".primary input").click ->
    this.select()

  $(".primary input").blur ->
    $(this).val(default_input_txt) if $(this).val() == ""
