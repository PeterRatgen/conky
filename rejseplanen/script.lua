require 'cairo'
require 'table'

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

  journey_data = rejse_parse()


  local f = io.popen("stat -c %Y /home/peter/.config/conky/rejseplanen/data.csv")
  local last_modified = f:read()
  last_modified = os.date("%X", last_modified)

  table.insert(journey_data, { number = "Sidst opdateret: " .. last_modified })

  print_all_journeys(cr, journey_data)

  cairo_surface_destroy(cs)
  cr = nil

end

function print_all_journeys (cr, journey_data)
  offset = 65
  for i = 0, 20, 1
  do
    journey_row(cr, journey_data[i+1], offset*i)
  end
end

function print_journey_row (cr, data_row, offset)
  x = 50
  text_height = 33

  journey_row_width = 880
  journey_row_height = 50
  cairo_set_source_rgba (cr, 200/255, 200/255, 200/255, 0.2);
  draw_rounded_rectangle(x, offset, journey_row_width, journey_row_height)

  highlight_offset = 10
  highlight_width = 120
  highlight_height = 50 - highlight_offset*2
  if string.match(data_row["number"], "IC") or string.match(data_row["number"], "Re") then
    cairo_set_source_rgba (cr, 200/255, 20/255, 20/255, 0.7);
    draw_rounded_rectangle (70,offset + highlight_offset, highlight_width, highlight_height)
  elseif string.match(data_row["number"], "Bus") then 
    cairo_set_source_rgba (cr, 20/255, 200/255, 20/255, 0.7);
    draw_rounded_rectangle (70,offset + highlight_offset, highlight_width, highlight_height)
  end

  cairo_set_source_rgb (cr, 1,1,1);
  cairo_move_to (cr, 80, text_height+offset) 
  cairo_show_text (cr, data_row["number"])
  cairo_move_to (cr, 225, text_height+offset) 
  cairo_show_text (cr, data_row["time"])
  cairo_move_to (cr, 370, text_height+offset) 
  cairo_show_text (cr, data_row["destination"])
  cairo_move_to (cr, 650, text_height+offset) 
  cairo_show_text (cr, data_row["depart"])
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

function rejse_parse()
  local data_list = {}
  for line in io.lines("/home/peter/.config/conky/rejseplanen/data.csv") do
    local number, time, destination, depart = line:match("%s*(.*),%s*(.*),%s*(.*),%s*(.* )")
    data_list[#data_list + 1] = {number = number, time = time, destination = destination, depart = depart}
  end
  return data_list
end



