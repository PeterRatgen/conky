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
  connection = assert (env:connect('rejseplanen','peter','peter1609','127.0.0.1',5432))
  -- fetch from the database
  cur = connection:execute("SELECT * FROM (SELECT * FROM departures ORDER BY id DESC LIMIT 20) as foo ORDER BY id ASC;")
  -- iterate over cursor and print
  line = cur:fetch({}, "a")
  offset = 60
  offset_modifier = 1
  print_journey_row (cr, offset_modifier * offset,'Tid','', 'Navn', nil, 'Retning', 'Stop')
  offset_modifier = offset_modifier + 1
  
  cur2 = connection:execute(string.format("SELECT (query) FROM journey_table WHERE departure_id=%d", line.id))

  local json = require("JSON")
  inspect = require("inspect")
  query = cur2:fetch({}, "a")

  local data = json:decde(query['query'])
  num_stops = data["JourneyDetail"]["JourneyName"]["routeIdxTo"] + 1
  stops = {}
  for i = 1, num_stops, 1 do
    if not data["JourneyDetail"]["Stop"][i]["name"]:match("Zone") then
      stops[#stops + 1] = data["JourneyDetail"]["Stop"][i]["name"]:match("[%a/æøåÆØÅéÉ%d%. ]*")
    end
  end 
  journey_data = {}; 
  journey_data.num_stops = #stops;
  journey_data.stops = stops
  
  cairo_set_font_size(cr, 18)
  for i = 1, journey_data.num_stops, 1 do
    cairo_move_to(cr, 950, 50+23*i)
    cairo_show_text(cr, journey_data.stops[i]['name'])
  end
  cairo_stroke(cr)


  last_modified = line.ts
  while line do
    journey_rows(cr, line, offset * offset_modifier)
    line = cur:fetch(line, "a")
    offset_modifier = offset_modifier + 1
  end

  last_mod = string.format("%s: %s",'Last modified', last_modified:match("%d*%-%d*%-%d*%s%d+:%d+:%d+"))
  print_journey_row(cr, offset_modifier * offset, '', '', last_mod, nil, '', '')
  cairo_stroke(cr)

  cur:close()
  connection:close()
  env:close()
  -- cleanup
  cairo_surface_destroy(cs)
  cr = nil
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
      delay = string.format("%d:%d", r_hour, r_minute)
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





