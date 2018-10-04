for i in sile/core/*.so; do
    echo $i
    install_name_tool -change /usr/local/opt/libpng/lib/libpng16.16.dylib @rpath/libpng16.16.dylib $i
    install_name_tool -change /usr/local/lib/libharfbuzz.0.dylib @rpath/libharfbuzz.0.dylib $i
    install_name_tool -change /usr/local/lib/libfreetype.6.dylib @rpath/libfreetype.6.dylib $i
    install_name_tool -change /usr/local/opt/freetype/lib/libfreetype.6.dylib @rpath/libfreetype.6.dylib $i
    install_name_tool -change /usr/local/lib/libtexpdf.0.dylib @rpath/libtexpdf.0.dylib $i
    install_name_tool -change /usr/local/lib/libfontconfig.1.dylib @rpath/libfontconfig.1.dylib $i
    install_name_tool -change /usr/local/opt/fontconfig/lib/libfontconfig.1.dylib @rpath/libfontconfig.1.dylib $i
    install_name_tool -change /usr/local/opt/icu4c/lib/libicuio.61.dylib @rpath/libicuio.61.dylib $i
    install_name_tool -change /usr/local/opt/icu4c/lib/libicuuc.61.dylib @rpath/libicuuc.61.dylib $i
    install_name_tool -change /usr/local/opt/icu4c/lib/libicudata.61.1.dylib @rpath/libicudata.61.1.dylib $i
    install_name_tool -change /usr/local/opt/icu4c/lib/libicui18n.61.dylib @rpath/libicui18n.61.dylib $i
    otool -L $i | grep local
done
