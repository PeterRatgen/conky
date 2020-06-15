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

  news_data = get_data()

  cairo_move_to(50,50)
  cairo_show_text (cr, news_data[1]['title'])
end

function get_data()
  local xml2lua = require("xml2lua")
  local handler = require("xmlhandler.tree")
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


