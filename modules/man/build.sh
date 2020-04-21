MAGISK_MODULE_HOMEPAGE=https://mdocml.bsd.lv/
MAGISK_MODULE_DESCRIPTION="Man page viewer from the mandoc toolset"
MAGISK_MODULE_LICENSE="BSD 3-Clause"
MAGISK_MODULE_VERSION=1.14.5
MAGISK_MODULE_REVISION=1
MAGISK_MODULE_SHA256=8219b42cb56fc07b2aa660574e6211ac38eefdbf21f41b698d3348793ba5d8f7
MAGISK_MODULE_SRCURL=http://mdocml.bsd.lv/snapshots/mandoc-${MAGISK_MODULE_VERSION}.tar.gz
MAGISK_MODULE_DEPENDS="less,libandroid-glob,zlib"
MAGISK_MODULE_BUILD_IN_SRC=yes
MAGISK_MODULE_RM_AFTER_INSTALL="usr/share/examples"

magisk_step_pre_configure() {
	LDFLAGS+=" -static -landroid-glob -lz -lc"
	echo "PREFIX=\"$MAGISK_PREFIX\"" > configure.local
	echo "CC=\"$CC\"" >> configure.local
	echo "MANDIR=\"/data/man\"" >> configure.local
	echo "CFLAGS=\"$CFLAGS --static -DNULL=0 $CPPFLAGS\"" >> configure.local
	echo "LDFLAGS=\"$LDFLAGS\"" >> configure.local
	#echo "LDADD=\" -lz -lc -landroid-glob\"" >> configure.local
	for HAVING in HAVE_FGETLN HAVE_MMAP HAVE_STRLCAT HAVE_STRLCPY HAVE_SYS_ENDIAN HAVE_ENDIAN HAVE_NTOHL HAVE_NANOSLEEP HAVE_O_DIRECTORY; do
		echo "$HAVING=1" >> configure.local
	done
	echo "HAVE_MANPATH=0" >> configure.local
	echo "HAVE_SQLITE3=1" >> configure.local
	printenv >> config.env
}

magisk_step_create_zipscripts() {
	echo "mount -o rw,remount /system;" >> service.sh
	echo "makewhatis -Q" >> service.sh
	echo "mount -o ro,remount /system;" >> service.sh
}
