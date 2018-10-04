    install_name_tool -change /usr/local/opt/libpng/lib/libpng16.16.dylib @rpath/libpng16.16.dylib $1
    install_name_tool -change /usr/local/lib/libharfbuzz.0.dylib @rpath/libharfbuzz.0.dylib $1
    install_name_tool -change /usr/local/lib/libfreetype.6.dylib @rpath/libfreetype.6.dylib $1
    install_name_tool -change /usr/local/lib/libtexpdf.0.dylib @rpath/libtexpdf.0.dylib $1
    install_name_tool -change /usr/local/lib/libfontconfig.1.dylib @rpath/libfontconfig.1.dylib $1
    install_name_tool -change /usr/local/opt/freetype/lib/libfreetype.6.dylib @rpath/libfreetype.6.dylib $1
    otool -L $1 | grep local
