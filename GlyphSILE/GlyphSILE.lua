local home = NSBundle:bundleForClass_(GlyphSILE).resourcePath
package.path = home.."/?.lua;"..home.."/lua-libraries/?.lua;"..home.."/lua-libraries/?/init.lua;"..package.path
package.cpath = home.."/shared-libraries/?.so;"..package.cpath
require("core/sile")

SILE.backend = "Glyphs" -- yes it is.
require("core/harfbuzz-shaper")

SILE.shapers.Glyphs = SILE.shapers.harfbuzz {
  shapeToken = function (self, text, options)
    options = SILE.font.loadDefaults(options)
    local font = Glyphs.font
    options.filename = font.tempOTFFont
    local scale = options.size / font.upm
    print("Scale is "..options.size.."/"..font.upm.." = "..scale)
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
        end
      end
    end
    return items
  end
}

SILE.shaper = SILE.shapers.Glyphs

SILE.outputter = { -- Blegh
  init = function () end
}

doGlyphSILE = function(s, v)
  local plain = require("classes/plain")
  local size = v.frame.size
  plain.options.papersize(size.width.."pt x "..size.height.."pt")
  SILE.documentState.documentClass = plain;
  local ff = plain:init()
  SILE.typesetter:init(ff)
  SILE.typesetter:typeset(s)
  SILE.typesetter:leaveHmode()
  SILE.typesetter:debugState()
  plain:finish()
end