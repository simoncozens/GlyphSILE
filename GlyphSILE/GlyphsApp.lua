Glyphs = NSApplication.sharedApplication
-- currentDocument
local object_with_pseudo_mt = {
  __tostring = function (o) return "<"..(o.Class)..">" end,
  __index = function(inObject, inKey)
    local pseudo = rawget(inObject,"pseudomembers")
    if pseudo and pseudo[inKey] then return pseudo[inKey](object) end
    local p = objc.getproperty(unwrap(inObject), inKey)
    if p then return p end
    inKey = inKey:gsub("_",":")
    p = objc.hasmethod(unwrap(inObject), inKey)
    if p then
      p = { name = inKey, target = inObject }
      setmetatable(p, method_mt)
      return p
    end
  end,
  __newindex =  function(inObject, inKey, inValue)
    if (objc.getproperty(unwrap(inObject), inKey)) then
        return sendMesg(inObject["WrappedObject"], 'setValue:forKeyPath:', inValue, inKey)
    end
    rawset(inObject, inKey, inValue)
  end
}
setmetatable(Glyphs, object_with_pseudo_mt)

Glyphs.pseudomembers = {
  currentDocument = function() return NSApplication.sharedApplication.currentFontDocument end,
  font = function () return NSApplication.sharedApplication.currentFontDocument and NSApplication.sharedApplication.currentFontDocument.font end
}

Glyphs.scriptAbbrevations =  GSGlyphsInfo.scriptAbrevations
Glyphs.scriptSuffixes = GSGlyphsInfo.scriptSuffixes
Glyphs.languageScripts = GSGlyphsInfo.languageScripts
Glyphs.languageData = GSGlyphsInfo.languageData
Glyphs.unicodeRanges = GSGlyphsInfo.unicodeRanges
Glyphs.open = function(self, Path, showInterface)
  local URL = NSURL:fileURLWithPath_(Path)
  local Doc = NSDocumentController.sharedDocumentController:openDocumentWithContentsOfURL_display_error_(URL, showInterface, nil)
  return Doc and Doc.font
end

Glyphs.showMacroWindow = function(self)
  self.delegate:showMacroWindow()
end

Glyphs.clearLog = function(self)
  self.delegate:clearConsole()
end

Glyphs.showGlyphInfoPanelWithSearchString = function(self,s)
  self.delegate:showGlyphInfoPanelWithSearchString_(s)
end

Glyphs.glyphInfoForName = function(self, s)
  if type(s)=="number" then s = string.format("%04X", s) end
  return GSGlyphsInfo:glyphInfoForName_(s)
end

Glyphs.glyphInfoForUnicode = function(self, s)
  return GSGlyphsInfo:glyphInfoForUnicode_(s)
end

Glyphs.niceGlyphName = function(self,s)
  return GSGlyphsInfo:niceGlyphNameForName_(s)
end

Glyphs.productionGlyphName = function(self,s)
  return GSGlyphsInfo:productionGlyphNameForName_(s)
end

Glyphs.ligatureComponents = function(self,s)
  return GSGlyphsInfo:_componentsForLigaName_(s)
end

Glyphs.addCallback = function (self, target, operation)
  Glyphs.delegate:addCallback_forOperation_(target, operation)
end

Glyphs.removeCallback = function (self, target, operation)
  if operation then
    Glyphs.delegate:removeCallback_forOperation_(target, operation)
  else
    Glyphs.delegate:removeCallback_(target)
  end
end

Glyphs.redraw = function ()
  NSNotificationCenter.defaultCenter:postNotificationName_object_("GSRedrawEditView", nil)
end


DRAWFOREGROUND = "DrawForeground"
DRAWBACKGROUND = "DrawBackground"
DRAWINACTIVE = "DrawInactive"

GSMOVE = 17
GSLINE = 1
GSCURVE = 35
GSOFFCURVE = 65
GSSHARP = 0
GSSMOOTH = 100

TOPGHOST = -1
STEM = 0
BOTTOMGHOST = 1
TTANCHOR = 2
TTSTEM = 3
TTALIGN = 4
TTINTERPOLATE = 5
TTDIAGONAL = 6
CORNER = 16
CAP = 17

TTDONTROUND = 4
TTROUND = 0
TTROUNDUP = 1
TTROUNDDOWN = 2
TRIPLE = 128

TEXT = 1
ARROW = 2
CIRCLE = 3
PLUS = 4
MINUS = 5

nodeConstants = {
  [17] = 'GSMOVE',
  [1] = 'GSLINE',
  [35] = 'GSCURVE',
  [65] = 'GSOFFCURVE',
  [0] = 'GSSHARP',
  [100] = 'GSSMOOTH',
}
hintConstants = {
  [-1] = 'TopGhost',
  [0] = 'Stem',
  [1] = 'BottomGhost',
  [2] = 'TTAnchor',
  [3] = 'TTStem',
  [4] = 'TTAlign',
  [5] = 'TTInterpolate',
  [6] = 'TTDiagonal',
  [16] = 'Corner',
  [17] = 'Cap',
}

local docsButJustGSDocuments = function(getFont)
  local docs = Glyphs.orderedDocuments
  local rv = {}
  for i =1,#docs do
    if docs[i]:isKindOfClass_(GSDocument) then rv[#rv+1] = getFont and docs[i].font or docs[i] end
  end
  return rv
end

local documentMt = {
  __index = function (t,k)
    return docsButJustGSDocuments(false)[k]
  end,
  __len = function () return #(docsButJustGSDocuments(false)) end
}
local documentProxy = {}
setmetatable(documentProxy, documentMt)
Glyphs.documents = documentProxy

local fontMt = {
  __index = function (t,k)
    return docsButJustGSDocuments(true)[k]
  end,
  __len = function () return #(docsButJustGSDocuments(false)) end
}
local fontProxy = {}
setmetatable(fontProxy, fontMt)
Glyphs.fonts = fontProxy

local glyphProxyMt = {
  __index = function (t,k)
    if type(k) == "string" then return rawget(t,"owner"):glyphForName_(k) end
    return rawget(t, k)
  end
}

-- XXX glyph.layers should produce an array, not a dictionary (See MGOrderedDictionary)
