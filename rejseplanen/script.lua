
require 'cairo'

function conky_main ()
	if conky_window == nil then return end

	local cs = cairo_xlib_surface_create (conky_window.display,
			conky_window.drawable, conky_window.visual, conky_window.width,
			conky_window.height)

	cr = cairo_create (cs)

	local updates = tonumber (conky_parse ('${updates}'))

	if updates > 5 then

		-- SETTINGS FOR INDICATOR BAR
		bar_bottom_left_x = 100
		bar_bottom_left_y = 100
		bar_width = 30
		bar_height = 100
		bar_value = tonumber (conky_parse ("${cpu}"))
		bar_max_value = 100

		-- Set bar background colors, 0.5, 0.5, 0.5, 1 = fully opaque grey.
		bar_bg_red = 0.5
		bar_bg_green = 0.5
		bar_bg_blue = 0.5
		bar_bg_alpha = 1

		-- Bar border settings.
		bar_border = 1 -- Set 1 for border or 0 for no border.

		-- Set border color rgba.
		border_red = 0
		border_green = 1
		border_blue = 1
		border_alpha = 1

		-- Set border thickness.
		border_width = 10

		-- Color change.
		-- Set value for first color change, low cpu usage to mid cpu usage.
		mid_value = 50

		-- Set "low" cpu usage color and alpha, ie bar color below 50% - 0, 1, 0,
		-- 1 = fully opaque green.
		lr, lg, lb, la = 0, 1, 0, 1

		-- Set "mid" cpu usage color, between 50 and 79 - 1, 1, 0, 1 = fully.
		-- Opaque yellow.
		mr, mg, mb, ma = 1, 1, 0, 1

		-- Set alarm value, this is the value at which bar color will change.
		alarm_value = 80

		-- Set alarm bar color, 1, 0, 0, 1 = red fully opaque.
		ar, ag, ab, aa = 1, 0, 0, 1

		-- End of settings.

		-- Draw bar.
		-- Draw background.
		cairo_set_source_rgba (cr, bar_bg_red, bar_bg_green, bar_bg_blue,
			bar_bg_alpha)
		cairo_rectangle (cr, bar_bottom_left_x, bar_bottom_left_y,
			bar_width, -bar_height)
		cairo_fill (cr)
		-- Draw indicator.
		if bar_value >= alarm_value then -- ie if value is greater or equal to 50.
			cairo_set_source_rgba (cr, ar, ag, ab, aa) -- Yellow.
		elseif bar_value >= mid_value then -- if bar_value is greater or equal to 80
			cairo_set_source_rgba (cr, mr, mg, mb, ma) -- Red.
		else
			cairo_set_source_rgba (cr, lr, lg, lb, la) -- Green.
		end
		scale = bar_height / bar_max_value
		indicator_height = scale * bar_value
		cairo_rectangle (cr, bar_bottom_left_x, bar_bottom_left_y, bar_width,
			-indicator_height)
		cairo_fill (cr)
		-- Draw border.
		cairo_set_source_rgba (cr, border_red, border_green, border_blue,
			border_alpha)
		cairo_set_line_width (cr, border_width)
		border_bottom_left_x = bar_bottom_left_x-(border_width / 2)
		border_bottom_left_y = bar_bottom_left_y+(border_width / 2)
		brec_width = bar_width + border_width

		-- Remember that we need to make this value negative at some point because
		-- we are drawing up.
		brec_height = bar_height + border_width 
		cairo_rectangle (cr, border_bottom_left_x, border_bottom_left_y,
			brec_width, -brec_height)
		cairo_stroke (cr)
	end

	cairo_destroy (cr)
	cairo_surface_destroy (cs)
	cr = nil

end
