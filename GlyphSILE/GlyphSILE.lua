local home = NSBundle:bundleForClass_(GlyphSILE).resourcePath
package.path = home.."/?.lua;"..home.."/lua-libraries/?.lua;"..home.."/lua-libraries/?/init.lua;"..package.path
package.cpath = home.."/core/?.so;"..package.cpath
require("core/sile")

doGlyphSILE = function(s, v)
    SILE.init()
    print(s)
    print(v)
end