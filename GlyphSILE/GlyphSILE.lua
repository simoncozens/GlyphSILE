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

  shapeToken = function (self, text, options)
    options = SILE.font.loadDefaults(options)
    local font = Glyphs.font
    options.filename = font.tempOTFFont
    local scale = options.size / font.upm -- design size?
    options.master = 'Light' --- XXX
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

SILE.shaper = SILE.shapers.Glyphs

local cursorX
local cursorY
SILE.outputter = { -- Blegh
  init = function () end,
  finish = function () end,
  moveTo = function (x,y)
    cursorX = x
    cursorY = globalv.frame.size.height - y
  end,
  setFont = function (options)
    -- later
  end,
  outputHbox = function (value,w)
    if value.complex then
      for i=1,#(value.items) do
        print("Drawing", tostring(value.items[i]))
        local glyph = value.items[i].layer
        if glyph then
          globalv:drawGSLayer_atX_atY_withSize_(glyph, cursorX + value.items[i].lsb, cursorY, value.items[i].size)
        end
        cursorX = cursorX + value.items[i].width
      end
      return
    end
  end
}

doGlyphSILE = function(s, v)
  globalv = v
  globals = s
  globalv:setNeedsDisplay_(true)
end

doSILEDisplay = function()
  local plain = require("classes/plain")
  local size = globalv.frame.size
  plain.options.papersize(size.width.."pt x "..size.height.."pt")
  SILE.documentState.documentClass = plain;
  local ff = plain:init()
  SILE.typesetter:init(ff)
  SILE.typesetter:typeset(globals)
  SILE.typesetter:leaveHmode()
  print("Calling output")
  SILE.typesetter:chuck() -- XXX
  SILE.typesetter:debugState()
  plain:finish()
end