require 'cairo'

function conky_main()
  if conky_window == nil then
    return
  end
  local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
  cr = cairo_create(cs)
  font = "Inconsolata"
  font_size = 25
  font_slant = CAIRO_FONT_SLANT_NORMAL
  font_face = CAIRO_FONT_WEIGHT_NORMAL
  cairo_select_font_face (cr, font, font_slant, font_face);
  cairo_set_font_size (cr, font_size)

  -- Initialize database and connection
  postg = require "luasql.postgres"
  env = postg.postgres()
  connection = assert (env:connect('rejseplanen','peter','peter1609','127.0.0.1', 5432))
  -- fetch from the database
  cur = connection:execute("SELECT * FROM (SELECT * FROM departures ORDER BY id DESC LIMIT 20) as foo ORDER BY id ASC;")
  -- iterate over cursor and print
  line = cur:fetch({}, "a")
  offset = 60
  offset_modifier = 1
  print_journey_row (cr, offset_modifier * offset,'Tid','', 'Navn', nil, 'Retning', 'Stop')
  offset_modifier = offset_modifier + 1
  last_modified = line.ts
  journey_data = get_journey_data(line, connection)
  local inspect = require "inspect"
  while line do
    journey_rows(cr, line, offset * offset_modifier)
    line = cur:fetch(line, "a")
    offset_modifier = offset_modifier + 1
  end
  cur:close()
  draw_journey(cr, journey_data) 
  connection:close()
  env:close()

  cairo_set_font_size(cr, font_size)
  last_mod = string.format("%s: %s",'Last modified', last_modified:match("%d*%-%d*%-%d*%s%d+:%d+:%d+"))
  print_journey_row(cr, offset_modifier * offset, '', '', last_mod, nil, '', '')
  cairo_stroke(cr)

  -- cleanup
  cairo_surface_destroy(cs)
  cr = nil
end

function draw_journey(cr, journey_data)
  line_x = 1080
  stop_x = 1100
  depTime_x = 1020
  rtDepTime_x = 960
  cairo_set_font_size(cr, 18)
  line_width = get_line_width(journey_data)
  for i = 1, journey_data.num_stops, 1 do
    cairo_arc(cr, line_x, 44+line_width*i, 5, 0, 2*3.14)
    cairo_fill(cr)
    cairo_stroke(cr)
  end
  cairo_set_line_width (cr, 2.0);
  cairo_move_to(cr, line_x, 44+line_width)
  cairo_line_to(cr, line_x, 44+line_width*journey_data.num_stops)
  cairo_stroke(cr)
  for i = 1, journey_data.num_stops, 1 do
    cairo_move_to(cr, rtDepTime_x, 50+line_width*i)
    if journey_data.stops[i]['rtDepTime'] then
      cairo_show_text(cr, journey_data.stops[i]['rtDepTime'])
    elseif journey_data.stops[i]['rtArrTime'] then
      cairo_show_text(cr, journey_data.stops[i]['rtArrTime'])
    end
    cairo_move_to(cr, depTime_x, 50+line_width*i)
    if journey_data.stops[i]['depTime'] then
      cairo_show_text(cr, journey_data.stops[i]['depTime'])
    else
      cairo_show_text(cr, journey_data.stops[i]['arrTime'])
    end
    cairo_move_to(cr, stop_x, 50+line_width*i)
    cairo_show_text(cr, journey_data.stops[i]['name'])
  end
  cairo_stroke(cr)
end

function get_line_width(journey_data)
  return 1310/journey_data.num_stops
end

function get_journey_data(line, connection)
  cur2 = connection:execute(string.format("SELECT (query) FROM journey_table WHERE departure_id=%d", line.id))

  local json = require("JSON")
  query = cur2:fetch({}, "a")

  local data = json:decode(query['query'])
  local inspect = require "inspect"
  if data["JourneyDetail"]["JourneyName"]["routeIdxTo"] then
    num_stops = data["JourneyDetail"]["JourneyName"]["routeIdxTo"] + 1
  else
    num_stops = data["JourneyDetail"]["JourneyName"][0]["routeIdxTo"] + 1
  end
  stops = {}
  for i = 1, num_stops, 1 do
    if not data["JourneyDetail"]["Stop"][i]["name"]:match("Zone") then
      stop = {}
      stop.name = data["JourneyDetail"]["Stop"][i]["name"]:match("[%a/æøüåÆØÅéÉ%d%. ]*")
      stop.depTime = data["JourneyDetail"]["Stop"][i]['depTime']
      stop.rtDepTime = data["JourneyDetail"]["Stop"][i]['rtDepTime']
      stop.arrTime = data["JourneyDetail"]["Stop"][i]['arrTime']
      stop.rtArrTime = data["JourneyDetail"]["Stop"][i]['rtArrTime']
      stops[#stops + 1] = stop
    end
  end 
  journey_data = {}; journey_data.num_stops = #stops; journey_data.stops = stops
  cur2:close()
  return journey_data
end

function journey_rows (cr, line, offset)
  -- Calculate the delay
  local delay
  local hour, minute, second = line.time:match("(%d+):(%d+):(%d+)")
  if line.rttime ~= nil
  then
    local r_hour, r_minute, r_second = line.rttime:match("(%d+):(%d+):(%d+)")
    if r_hour and r_minute and hour and minute ~= nil
    then
      delay = math.abs((tonumber(r_hour)*60+tonumber(r_minute)) - (tonumber(hour)*60+tonumber(minute)))
    end
    if delay >= 10 then
      if 9 < tonumber(r_minute)  then
        delay = string.format("%d:%d", r_hour, r_minute)
      else 
        delay = string.format("%d:0%d", r_hour, r_minute)
      end
    end 
  end
  print_journey_row(cr, offset, hour, minute, line.name, delay, line.direction, line.stop)
end

function print_journey_row (cr, offset, hour, minute, name, delay, direction, stop )
  x = 50 --vertical offset of cards
  text_height = 31 -- text height relative to the card
  -- Draw the rectange
  journey_row_width = 880
  journey_row_height = 45
  cairo_set_source_rgba (cr, 200/255, 200/255, 200/255, 0.2);
  draw_rounded_rectangle(x, offset, journey_row_width, journey_row_height)
  -- Calculate the placement of background rectangle
  highlight_offset = 9
  word_width = 15.5
  highlight_height = journey_row_height - highlight_offset*2
  -- Draw train or bus background rectangle
  if string.match(name, "ICL") then
    cairo_set_source_rgba (cr, 175/255, 178/255, 24/255, 0.7);
    draw_rounded_rectangle (70,offset + highlight_offset, word_width * string.len(name), highlight_height)
  elseif string.match(name, "IC") then
    cairo_set_source_rgba (cr, 200/255, 20/255, 20/255, 0.7);
    draw_rounded_rectangle (70,offset + highlight_offset, word_width * string.len(name), highlight_height)
  elseif string.match(name, "Re") then
    cairo_set_source_rgba (cr, 6/255, 118/255, 6/255, 0.7);
    draw_rounded_rectangle (70,offset + highlight_offset, word_width * string.len(name), highlight_height)
  elseif string.match(name, "Bus") then 
    cairo_set_source_rgba (cr, 20/255, 200/255, 20/255, 0.7);
    draw_rounded_rectangle (70,offset + highlight_offset, word_width * string.len(name), highlight_height)
  end
  -- Print name of departure
  cairo_set_source_rgb (cr, 1,1,1);
  cairo_move_to (cr, 80, text_height+offset) 
  cairo_show_text (cr, name)
  -- Print time of departure
  cairo_move_to (cr, 225, text_height+offset) 
  cairo_show_text (cr, string.format("%s:%s", hour, minute))
  -- Print the delay
  if delay ~= nil
  then
    cairo_set_source_rgb (cr, 1, 0.05, 0.05)
    cairo_move_to (cr, 295, text_height+offset) 
    if string.len(tostring(delay)) <= 3 then
      cairo_show_text (cr, " +" .. tostring(delay))
    else
      cairo_show_text (cr, tostring(delay))
    end
    cairo_stroke (cr)
    cairo_set_source_rgb (cr, 1, 1, 1)
  end
  -- Print direction
  cairo_move_to (cr, 370, text_height+offset) 
  cairo_show_text (cr, direction)
  -- Print stop of departure
  cairo_move_to (cr, 650, text_height+offset) 
  cairo_show_text (cr, string.match(stop, '%s*([%a %.]*)'))
  cairo_stroke (cr)
end

function draw_rounded_rectangle(x, y, width, height)
  corner_radius = height/4
  aspect = 1.0

  radius = corner_radius / aspect
  degrees = 3.14 / 180.0

  cairo_new_sub_path (cr);
  cairo_arc (cr, x + width - radius, y + radius, radius, -90 * degrees, 0 * degrees);
  cairo_arc (cr, x + width - radius, y + height - radius, radius, 0 * degrees, 90 * degrees);
  cairo_arc (cr, x + radius, y + height - radius, radius, 90 * degrees, 180 * degrees);
  cairo_arc (cr, x + radius, y + radius, radius, 180 * degrees, 270 * degrees);
  cairo_close_path (cr);

  cairo_fill_preserve (cr);
  cairo_stroke (cr)
end
