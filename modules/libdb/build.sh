MAGISK_MODULE_HOMEPAGE=https://www.oracle.com/database/berkeley-db
MAGISK_MODULE_DESCRIPTION="The Berkeley DB embedded database system (library)"
MAGISK_MODULE_LICENSE="BSD 3-Clause"
MAGISK_MODULE_MAINTAINER="Vishal Biswas @vishalbiswas"
MAGISK_MODULE_VERSION=18.1.40
MAGISK_MODULE_REVISION=1
MAGISK_MODULE_SHA256=0cecb2ef0c67b166de93732769abdeba0555086d51de1090df325e18ee8da9c8
MAGISK_MODULE_SRCURL=https://fossies.org/linux/misc/db-${MAGISK_MODULE_VERSION}.tar.gz
MAGISK_MODULE_EXTRA_CONFIGURE_ARGS="
--enable-hash
--enable-smallbuild
--enable-compat185
db_cv_atomic=gcc-builtin
--enable-cxx
"
MAGISK_MODULE_RM_AFTER_INSTALL="docs"
MAGISK_MODULE_BREAKS="libdb-dev"
MAGISK_MODULE_REPLACES="libdb-dev"

magisk_step_pre_configure() {
	MAGISK_MODULE_SRCDIR=$MAGISK_MODULE_SRCDIR/dist
	CFLAGS+=" -I/home/builder/lib/android-ndk/sysroot/usr/include $CFLAGS"
}
