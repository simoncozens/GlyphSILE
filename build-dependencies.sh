cp /usr/local/lib/libpng*.dylib frameworks/
cd frameworks
sh ../relocate-self.sh libpng*.dylib
cd ..

echo "================="
echo "Building Harfbuzz"
echo "================="

cd harfbuzz
./configure --without-cairo --without-glib --without-graphite2 --without-icu --without-fontconfig --without-freetype2
make

echo "==================="
echo "Relocating Harfbuzz"
echo "==================="

cd ..
cp harfbuzz/src/.libs/libharfbuzz.0.dylib frameworks
cd frameworks
sh ../relocate-self.sh libharfbuzz.0.dylib
sh ../relocate-a-thing.sh libharfbuzz.0.dylib

echo "================="
echo "Building Freetype"
echo "================="
wget http://download.savannah.gnu.org/releases/freetype/freetype-2.9.tar.bz2 && tar xf freetype-2.9.tar.bz2 && cd freetype-2.9 && ./autogen.sh && ./configure && make -j4 && cd ..

cp freetype-2.9/objs/.libs/libfreetype* frameworks
sh ../relocate-self.sh libfreetype.6.dylib
sh ../relocate-a-thing.sh libfreetype.6.dylib
sh ../relocate-self.sh libfreetype.dylib
sh ../relocate-a-thing.sh libfreetype.dylib

echo "============="
echo "Building SILE"
echo "============="
cd sile
./configure --disable-linklua --without-libthai
make
cd ..
cp sile/libtexpdf/.libs/libtexpdf.0.dylib frameworks/
cd frameworks
sh ../relocate-self.sh libtexpdf.0.dylib
sh ../relocate-a-thing.sh libtexpdf.0.dylib
cd ..
rm sile/core/justenoughicu.so
sh relocate-sile-shared-objects.sh
cp sile/core/*icu shared-libraries