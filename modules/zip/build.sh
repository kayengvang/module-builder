MAGISK_MODULE_HOMEPAGE=http://www.info-zip.org/
MAGISK_MODULE_DESCRIPTION="Tools for working with zip files"
MAGISK_MODULE_LICENSE="BSD"
MAGISK_MODULE_VERSION=3.0
MAGISK_MODULE_REVISION=2
MAGISK_MODULE_SRCURL=https://downloads.sourceforge.net/infozip/zip30.tar.gz
MAGISK_MODULE_SHA256=f0e8bb1f9b7eb0b01285495a2699df3a4b766784c1765a8f1aeedf63c0806369
MAGISK_MODULE_DEPENDS="libandroid-support, libbz2"
MAGISK_MODULE_BUILD_IN_SRC=yes

magisk_step_make() {
	cp $MAGISK_PREFIX/lib/libbz2.a $MAGISK_MODULE_SRCDIR/bzip2/libbz2.a
	cp $MAGISK_PREFIX/include/bzlib.h $MAGISK_MODULE_SRCDIR/bzip2/bzlib.h

        make -f unix/Makefile clean
	make -f unix/Makefile generic -j $(nproc) CC=$CC #LD=$LD
     	mkdir -p $MAGISK_MODULE_MASSAGEDIR/$MAGISK_PREFIX/bin
	cp $MAGISK_MODULE_SRCDIR/zip $MAGISK_MODULE_MASSAGEDIR/$MAGISK_PREFIX/bin/zip
	cp $MAGISK_MODULE_SRCDIR/zipcloak $MAGISK_MODULE_MASSAGEDIR/$MAGISK_PREFIX/bin/zipcloak
	cp $MAGISK_MODULE_SRCDIR/zipnote $MAGISK_MODULE_MASSAGEDIR/$MAGISK_PREFIX/bin/zipnote
	cp $MAGISK_MODULE_SRCDIR/zipsplit $MAGISK_MODULE_MASSAGEDIR/$MAGISK_PREFIX/bin/zipsplit
}
