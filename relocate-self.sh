install_name_tool -id @rpath/$1 $1
shopt -s extglob
OLDPATH=`otool -L $1 | grep $1 | grep 'usr' | awk '{print $1}' |head -1` 
echo $OLDPATH
if  [ -n "${OLDPATH##+([[:space:]])}" ]
then
install_name_tool -change $OLDPATH @rpath/$1 $1
fi
