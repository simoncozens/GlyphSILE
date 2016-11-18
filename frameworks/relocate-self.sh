install_name_tool -id @rpath/$1 $1
OLDPATH=`otool -L $1 | grep $1 | grep 'usr' | awk '{print $1}' |head -1` 
install_name_tool -change $OLDPATH @rpath/$1 $1
