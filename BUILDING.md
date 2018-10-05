To build GlyphSILE and its needed shared libraries from scratch, the `build-dependencies.sh` should cover most of it. Then run `xcode-build` and the plugin should appear in your Glyphs plugins directory.

If you need to do it manually:

* Frameworks 

** libpng

Copy this over and relocate

    cp /usr/local/lib/libpng*.dylib frameworks/

** Harfbuzz

Make a minimal-dependency Harfbuzz:

    $ ./configure --without-cairo --without-glib --without-graphite2 --without-icu --without-fontconfig --without-freetype2

Copy it to frameworks:

    $ cp src/.libs/libharfbuzz.0.dylib ~/hacks/glyphs/GlyphSILE/frameworks

Relocate self-references to rpath:

    $ sh relocate-self.sh libharfbuzz.0.dylib

** Freetype2

Harfbuzz and freetype2 have mutual dependency relationships. Rebuild your freetype2 to link against your minimal harfbuzz. 

Relocate using `relocate-self` twice, then fix up:

    $ install_name_tool -change /usr/local/opt/libpng/lib/libpng16.16.dylib @rpath/libpng16.16.dylib libfreetype.6.dylib

** libtexpdf

This will need a copy of libpng installed and relocated. Make `libtexpdf` as normal, copy to `frameworks` and then:

    $ sh relocate-self.sh libtexpdf.0.dylib
    $ install_name_tool -change /usr/local/opt/libpng/lib/libpng16.16.dylib @path/libpng16.16.dylib libtexpdf.0.dylib

Copy in `libpng16.16.dylib` and relocate:

    $ sh relocate-self.sh libpng16.16.dylib

** Other libraries

Make a minimal freetype, and relocate all paths to `@rpath`; also `libfontconfig`.

SILE now requires ICU, which is fun. :-( We copy it rather than build it. 


* SILE libraries

In SILE, build with `./configure --disable-lualink`. Run make in `sile/`. Check your minimal Harfbuzz is installed and being linked against. Relocate all shared objects.

    sh relocate-sile-shared-objects.sh

and check output. Copy them to `shared-libraries`.
