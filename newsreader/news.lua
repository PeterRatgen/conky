require 'cairo'

function conky_main()
  if conky_window == nil then
    return
  end
  local cs = cairo_xlib_surface_create(conky_window.display, conky_window.drawable, conky_window.visual, conky_window.width, conky_window.height)
  cr = cairo_create(cs)
  font = "Noto Sans"
  font_size = 18
  font_slant = CAIRO_FONT_SLANT_NORMAL
  font_face = CAIRO_FONT_WEIGHT_NORMAL
  cairo_select_font_face (cr, font, font_slant, font_face);
  cairo_set_font_size (cr, font_size)

  news_data = get_data()

  cairo_set_source_rgb (cr, 1,1,1)
  for i = 1, 20, 1 do
    hyperlink = string.format("uri='%s'", news_data[i]['link'])
    font_size = 20
    cairo_set_font_size (cr, font_size)
    cairo_move_to(cr, 50, 60*i)
    cairo_show_text (cr, news_data[i]['title'])
    cairo_stroke(cr)

    font_size = 14
    cairo_set_font_size (cr, font_size)
    cairo_move_to(cr, 50, 60*i + 20)
    cairo_show_text (cr, news_data[i]['description'])
    cairo_stroke(cr)
  end


  cairo_surface_destroy(cs)
  cr = nil
end

function get_data()
  local xml2lua = require("lua-json")
  local https = require("ssl.https")
  
  local body, statusCode, headers, statusText = https.request("https://www.dr.dk/nyheder/service/feeds/allenyheder")

  local parser = xml2lua.parser(handler)
  parser:parse(body)

  news_data = {}
  count = 0
  for i, p in pairs(handler.root.rss.channel.item) do
    article = {}
    article["title"] = p.title
    article["description"] = p.description
    article['link'] = p.link
    article['img'] = p["DR:XmlImageArticle"]["DR:ImageUri620x349"]
    news_data[#news_data+1] = article 
  end
  return news_data
end


