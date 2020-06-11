require 'cairo'

function conky_main()
  if conky_window == nil then
    return
  end
  local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
  cr = cairo_create(cs)
  io.stderr:write('window is: ', conky_window.width,' x ', conky_window.height)
  local updates=tonumber(conky_parse('${updates}'))
  font="Mono"
  font_size=16
  text= tostring(updates)
  xpos,ypos=20,20
  red,green,blue,alpha=1,1,1,1
  font_slant=CAIRO_FONT_SLANT_NORMAL
  font_face=CAIRO_FONT_WEIGHT_NORMAL
  cairo_select_font_face (cr, font, font_slant, font_face);
  cairo_set_font_size (cr, font_size)
  cairo_set_source_rgba (cr,red,green,blue,alpha)
  cairo_move_to (cr,xpos,ypos)
  cairo_show_text (cr,text)

  draw_grid(cr, 20, 4)

  rejse_data = rejse_parse()

  print_data_grid (cr, rejse_data)

  cairo_destroy(cr)
  cairo_surface_destroy(cs)
  cr=nil

end

function print_data_grid (cr, rejse_data)
  ystep = 60
  for i = 1, 20, 1
  do
    cairo_move_to (cr, 50+45, 40+ystep*i)  
    cairo_show_text (cr, rejse_data[i]["number"])
    cairo_move_to (cr, 300, 40+ystep*i)  
    cairo_show_text (cr, rejse_data[i]["time"])
    cairo_move_to (cr, 500, 40+ystep*i)  
    cairo_show_text (cr, rejse_data[i]["destination"])
    cairo_move_to (cr, 700, 40+ystep*i)  
    cairo_show_text (cr, rejse_data[i]["depart"])
  end
end


function draw_grid(canvas, x_fields, y_fields)
  cairo_set_line_width (cr, 2);
  x_start = 50
  y_start = 50
  x_end = 250
  ystep = 60
  xstep = 200
  for i = 0, x_fields, 1
  do
    cairo_move_to (canvas, x_start, y_start + ystep * i)
    cairo_line_to (canvas, x_start + y_fields * xstep, y_start + ystep * i)
  end
  cairo_stroke(canvas)

  for i = 0, y_fields, 1
  do
    cairo_move_to (canvas, x_start + xstep * i, y_start)
    cairo_line_to (canvas, y_start + xstep * i, x_start + ystep * x_fields)
  end
  cairo_stroke (canvas)
end

function rejse_parse()
  local data_list = {}
  for line in io.lines("data.csv") do
    local number, time, destination, depart = line:match("%s*(.-),%s*(.-),%s*(.-),%s*(.- )")
    data_list[#data_list + 1] = {number = number, time = time, destination = destination, depart = depart}
  end
  return data_list
end



