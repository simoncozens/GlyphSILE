local home = NSBundle:bundleForClass_(GlyphSILE).resourcePath
package.path = home.."/?.lua;"..home.."/lua-libraries/?.lua;"..home.."/lua-libraries/?/init.lua;"..package.path
package.cpath = home.."/shared-libraries/?.so;"..package.cpath
require("core/sile")

SILE.backend = "Glyphs" -- yes it is.
require("core/libtexpdf-output")
require("core/harfbuzz-shaper")

SILE.shapers.Glyphs = SILE.shapers.harfbuzz {
  preAddNodes = function(self, items, nnodeValue) -- Check for complex nodes
    nnodeValue.complex = true
  end,

  shapeToken = function (self, text, orig)
    options = SILE.font.loadDefaults(orig)
    print("Shaping token "..text, tostring(options))
    if not options.family:match("^Glyphs:") then -- abuse
      print("Using harfbuzz")
      return SILE.shapers.harfbuzz:shapeToken(text, orig)
    end
    local font = self.gsfont
    options.filename = font.tempOTFFont
    local scale = options.size / font.upm -- design size?
    print("Calling harfbuzz on OTFfont "..font.tempOTFFont)
    local items = SILE.shapers.harfbuzz:shapeToken(text, options)
    local masterid = options.family:gsub("Glyphs:Master:","")
    local master = font.masters[masterid]
    for i =1,#items do
      local g = font.glyphs[items[i].name]
      if g then
        local layer = g.layers[masterid]
        if layer then
          items[i].width = layer.width * scale
          items[i].glyphAdvance = layer.width  * scale
          items[i].height = master.ascender  * scale
          items[i].depth = -master.descender * scale
          items[i].lsb = layer.LSB * scale
          items[i].layer = layer
          items[i].size = scale
        end
      end
    end
    print(tostring(items))
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
    print("Moving to ",x,y)
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
      local previousLayer = nil
      for i=1,#(value.items) do
        local layer = value.items[i].layer
        xPos = cursorX
        yPos = cursorY
        if value.items[i].x_offset then xPos = xPos + value.items[i].x_offset end
        if value.items[i].y_offset then yPos = yPos + value.items[i].y_offset end
        if layer then
          if previousLayer then
            kerning = previousLayer:rightKerningForLayer_(layer)
            if kerning < 30000 then
              cursorX = cursorX + (kerning * value.items[i].size)
            end
          end
          SILE.outputter.nsview:drawGSLayer_atX_atY_withSize_(layer, xPos,yPos, value.items[i].size)
        else
          SILE.outputter.nsview:drawGlyph_atX_atY_(value.items[i].codepoint, xPos,yPos)
        end
        previousLayer = layer
        cursorX = cursorX + value.items[i].width
      end
      return
    end
  end
}

SILE.shaper = SILE.shapers.Glyphs
SILE.outputter = SILE.outputters.Glyphs
SU.error = function (message,bug)
  if(SILE.currentCommand and type(SILE.currentCommand) == "table") then
    print("\n! "..message.. " at "..SILE.currentlyProcessingFile.." l."..(SILE.currentCommand.line)..", col."..(SILE.currentCommand.col))
  else
    print("\n! "..message.. " at "..SILE.currentlyProcessingFile)
  end
  if bug then print(debug.traceback()) end
  SILE.outputter:finish()
  -- Don't call os.exit, it's confusing...
end

local stringToTypeset
local fontsize
-- local mode

doGlyphSILE = function(s, v, fs, m)
  stringToTypeset = s
  mode = m
  SILE.outputters.Glyphs.nsview:setNeedsDisplay_(true)
  fontsize = fs
  SILE.fontCache = {}
end

doSILEDisplay = function(nsview)
  SILE.outputters.Glyphs.nsview = nsview
  if not stringToTypeset or not mode then return end
  local plain = require("classes/plain")
  local size = nsview.frame.size
  plain.options.papersize(size.width.."pt x "..size.height.."pt")
  SILE.outputters.Glyphs.height = size.height
  SILE.documentState.documentClass = plain;
  local ff = plain:init()
  SILE.typesetter:init(ff)
  SILE.call("nofolios")
  if fontsize > 0 then SILE.settings.set("font.size", fontsize) end
  if mode and mode.filename then
    SILE.settings.set("font.filename", mode.filename)
  else
    SILE.settings.set("font.family", mode.family)
    SILE.shapers.Glyphs.gsfont = mode.font
    SILE.settings.set("font.filename", "")
  end
  SILE.doTexlike(stringToTypeset)
  SILE.typesetter:chuck() -- XXX
  plain:finish()
end

SILE.debugFlags["fonts"] = true
