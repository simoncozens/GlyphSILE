local home = NSBundle:bundleForClass_(GlyphSILE).resourcePath
package.path = home.."/?.lua;"..home.."/lua-libraries/?.lua;"..home.."/lua-libraries/?/init.lua;"..package.path
package.cpath = home.."/shared-libraries/?.so;"..package.cpath
require("core/sile")

SILE.backend = "Glyphs" -- yes it is.
require("core/harfbuzz-shaper")

SILE.shapers.Glyphs = SILE.shapers.harfbuzz {
  preAddNodes = function(self, items, nnodeValue) -- Check for complex nodes
    nnodeValue.complex = true
  end,

  shapeToken = function (self, text, orig)
    options = SILE.font.loadDefaults(orig)
    if not options.font:match("^Glyphs:") then -- abuse
      return SILE.shapers.harfbuzz:shapeToken(text, orig)
    end
    local font = Glyphs.font
    options.filename = font.tempOTFFont
    local scale = options.size / font.upm -- design size?
    local master = font.masters[1] -- XXX
    local items = SILE.shapers.harfbuzz:shapeToken(text, options)

    for i =1,#items do
      local g = font.glyphs[items[i].name]
      if g then
        local layer = g.layers[master.id]
        if layer then
          items[i].width = layer.width * scale
          items[i].glyphAdvance = layer.width  * scale
          items[i].height = master.ascender  * scale
          items[i].depth = -master.descender * scale
          items[i].lsb = layer.LSB * scale
          items[i].layer = layer
          items[i].size = options.size -- XXX
        end
      end
    end
    return items
  end
}

local cursorX
local cursorY
if (not SILE.outputters) then SILE.outputters = {} end
local lastkey
SILE.outputters.Glyphs = {
  nsview = nil,
  height = nil,
  init = function () end,
  finish = function () end,
  newPage = function () lastkey = nil end,
  moveTo = function (x,y)
    cursorX = x
    cursorY = SILE.outputter.height - y
  end,
  setFont = function (options)
    -- if SILE.font._key(options) == lastkey then return end
    lastkey = SILE.font._key(options)
    font = SILE.font.cache(options, SILE.shaper.getFace)
    font.data = nil
    SILE.outputters.Glyphs.nsview:loadFontFromPath_withHeight_(font.filename, font.pointsize)
    -- later
  end,
  outputHbox = function (value,w)
    if value.complex then
      for i=1,#(value.items) do
        local glyph = value.items[i].layer
        if glyph then
          SILE.outputter.nsview:drawGSLayer_atX_atY_withSize_(glyph, cursorX, cursorY, value.items[i].size)
        else
          SILE.outputter.nsview:drawGlyph_atX_atY_(value.items[i].codepoint, cursorX, cursorY)
        end
        cursorX = cursorX + value.items[i].width
      end
      return
    end
  end
}

SILE.shaper = SILE.shapers.Glyphs
SILE.outputter = SILE.outputters.Glyphs

local stringToTypeset
local fontsize
doGlyphSILE = function(s, v, fs)
  stringToTypeset = s
  SILE.outputters.Glyphs.nsview:setNeedsDisplay_(true)
  fontsize = fs
end


doSILEDisplay = function(nsview)
  SILE.outputters.Glyphs.nsview = nsview
  if not stringToTypeset then return end
  local plain = require("classes/plain")
  local size = nsview.frame.size
  plain.options.papersize(size.width.."pt x "..size.height.."pt")
  SILE.outputters.Glyphs.height = size.height
  SILE.documentState.documentClass = plain;
  local ff = plain:init()
  SILE.typesetter:init(ff)
  if fontsize > 0 then SILE.settings.set("font.size", fontsize) end
  SILE.settings.set("font.family", "Glyphs:Master:1")
  SILE.doTexlike(stringToTypeset)
  SILE.typesetter:leaveHmode()
  SILE.typesetter:chuck() -- XXX
  plain:finish()
end