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

  postg = require "luasql.postgres"
  env = postg.postgres()
  connection = assert (env:connect('rejseplanen','peter','peter1609','127.0.0.1',5432))
  cur = connection:execute("SELECT * FROM (SELECT * FROM departures ORDER BY id DESC LIMIT 20) as foo ORDER BY id ASC;")

  line = cur:fetch({}, "a")
  offset = 60
  off_mod = 0
  while line do
    print_journey_row(cr, line, offset*off_mod)
    line = cur:fetch(line, "a")
    off_mod = off_mod + 1
  end

  cairo_surface_destroy(cs)
  cr = nil
end


function print_journey_row (cr, line, offset)
  x = 50
  text_height = 31

  journey_row_width = 880
  journey_row_height = 45
  cairo_set_source_rgba (cr, 200/255, 200/255, 200/255, 0.2);
  draw_rounded_rectangle(x, offset, journey_row_width, journey_row_height)

  highlight_offset = 9
  highlight_width = 120
  highlight_height = journey_row_height - highlight_offset*2
  if string.match(line.name, "IC") or string.match(line.name, "Re") then
    cairo_set_source_rgba (cr, 200/255, 20/255, 20/255, 0.7);
    draw_rounded_rectangle (70,offset + highlight_offset, highlight_width, highlight_height)
  elseif string.match(line.name, "Bus") then 
    cairo_set_source_rgba (cr, 20/255, 200/255, 20/255, 0.7);
    draw_rounded_rectangle (70,offset + highlight_offset, highlight_width, highlight_height)
  end

  local delay
  local hour, minute, second = line.time:match("(%d+):(%d+):(%d+)")
  if line.rttime ~= nil
  then
    local r_hour, r_minute, r_second = line.rttime:match("(%d+):(%d+):(%d+)")
    if r_hour and r_minute and hour and minute ~= nil
    then
      delay = math.abs((tonumber(r_hour)-tonumber(hour))*60 + tonumber(minute)-tonumber(r_minute))
    end
  end

  cairo_set_source_rgb (cr, 1,1,1);
  cairo_move_to (cr, 80, text_height+offset) 
  cairo_show_text (cr, line.name)
  cairo_move_to (cr, 225, text_height+offset) 
  cairo_show_text (cr, string.format("%s:%s", hour, minute))
  if delay ~= nil
  then
    cairo_set_source_rgb (cr, 1, 0.05, 0.05)
    cairo_move_to (cr, 295, text_height+offset) 
    cairo_show_text (cr, " +" .. tostring(delay))
    cairo_stroke (cr)
    cairo_set_source_rgb (cr, 1, 1, 1)
  end
  cairo_move_to (cr, 370, text_height+offset) 
  cairo_show_text (cr, line.direction)
  cairo_move_to (cr, 650, text_height+offset) 
  cairo_show_text (cr, string.match(line.stop, '%s*([%a %.]*)'))
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




