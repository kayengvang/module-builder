MAGISK_MODULE_HOMEPAGE=https://python.org/
MAGISK_MODULE_DESCRIPTION="Python 3 programming language intended to enable clear programs"
MAGISK_MODULE_LICENSE="PythonPL"
_MAJOR_VERSION=3.9
_MINOR_VERSION=0
MAGISK_MODULE_VERSION=${_MAJOR_VERSION}.${_MINOR_VERSION}
MAGISK_MODULE_SRCURL=https://www.python.org/ftp/python/${MAGISK_MODULE_VERSION}/Python-${MAGISK_MODULE_VERSION}.tar.xz
MAGISK_MODULE_SHA256=9c73e63c99855709b9be0b3cc9e5b072cb60f37311e8c4e50f15576a0bf82854
MAGISK_MODULE_DEPENDS="gdbm, libandroid-support, libbz2, libcrypt, libffi, liblzma, libsqlite, ncurses, ncurses-ui-libs, openssl, readline, zlib"
MAGISK_MODULE_RECOMMENDS="clang"
MAGISK_MODULE_SUGGESTS="python-tkinter"
MAGISK_MODULE_BREAKS="python2 (<= 2.7.15), python-dev"
MAGISK_MODULE_REPLACES="python-dev"

# Set ac_cv_func_wcsftime=no to avoid errors such as "character U+ca0025 is not in range [U+0000; U+10ffff]"
# when executing e.g. "from time import time, strftime, localtime; print(strftime(str('%Y-%m-%d %H:%M'), localtime()))"
MAGISK_MODULE_EXTRA_CONFIGURE_ARGS="ac_cv_file__dev_ptmx=yes ac_cv_file__dev_ptc=no ac_cv_func_wcsftime=no"
# Avoid trying to include <sys/timeb.h> which does not exist on android-21:
MAGISK_MODULE_EXTRA_CONFIGURE_ARGS+=" ac_cv_func_ftime=no"
# Avoid trying to use AT_EACCESS which is not defined:
MAGISK_MODULE_EXTRA_CONFIGURE_ARGS+=" ac_cv_func_faccessat=no"
# The gethostbyname_r function does not exist on device libc:
MAGISK_MODULE_EXTRA_CONFIGURE_ARGS+=" ac_cv_func_gethostbyname_r=no"
MAGISK_MODULE_EXTRA_CONFIGURE_ARGS+=" --build=$MAGISK_BUILD_TUPLE --prefix=/data/python --with-system-ffi --without-ensurepip -with-openssl=$MAGISK_PREFIX --enable-shared"
# Hard links does not work on Android 6:
MAGISK_MODULE_EXTRA_CONFIGURE_ARGS+=" ac_cv_func_linkat=no"
# Posix semaphores are not supported on Android:
MAGISK_MODULE_EXTRA_CONFIGURE_ARGS+=" ac_cv_posix_semaphores_enabled=no"
# Do not assume getaddrinfo is buggy when cross compiling:
MAGISK_MODULE_EXTRA_CONFIGURE_ARGS+=" ac_cv_buggy_getaddrinfo=no"
MAGISK_MODULE_EXTRA_CONFIGURE_ARGS+=" --enable-loadable-sqlite-extensions"
# Fix https://github.com/termux/termux-packages/issues/2236:
MAGISK_MODULE_EXTRA_CONFIGURE_ARGS+=" ac_cv_little_endian_double=yes"
# Force disable semaphores (Android does not support them).
MAGISK_MODULE_EXTRA_CONFIGURE_ARGS+=" ac_cv_func_sem_open=no"
MAGISK_MODULE_EXTRA_CONFIGURE_ARGS+=" ac_cv_func_sem_timedwait=no"
MAGISK_MODULE_EXTRA_CONFIGURE_ARGS+=" ac_cv_func_sem_getvalue=no"

MAGISK_MODULE_RM_AFTER_INSTALL="
lib/python${_MAJOR_VERSION}/test
lib/python${_MAJOR_VERSION}/*/test
lib/python${_MAJOR_VERSION}/*/tests
"

magisk_step_pre_configure() {
	sudo mkdir -p /data/python
	sudo chown builder:builder /data/python
	[[ -f "/data/python" ]] && sudo rm -r /data/python/*
	LDFLAGS+=" -Wl,-rpath=\"/data/python/lib\" -Wl,--enable-new-dtags"
	# -O3 gains some additional performance on at least aarch64.
	CFLAGS="${CFLAGS/-Oz/-O3}"

	# Needed when building with clang, as setup.py only probes
	# gcc for include paths when finding headers for determining
	# if extension modules should be built (specifically, the
	# zlib extension module is not built without this):
	CPPFLAGS+=" -I$MAGISK_STANDALONE_TOOLCHAIN/sysroot/usr/include"
	LDFLAGS+=" -L$MAGISK_STANDALONE_TOOLCHAIN/sysroot/usr/lib"
	#LIBS=" -lbz2 -lssl -lgdbm -lreadline -lncursesw"
	if [ $MAGISK_ARCH = x86_64 ]; then LDFLAGS+=64; fi
}

magisk_step_post_make_install() {
	(cd /data/python/bin
	 ln -sf idle${_MAJOR_VERSION} idle
	 ln -sf python${_MAJOR_VERSION} python
	 ln -sf python${_MAJOR_VERSION}-config python-config
	 ln -sf pydoc${_MAJOR_VERSION} pydoc)
	(cd $MAGISK_PREFIX/usr/share/man/man1
	 ln -sf python${_MAJOR_VERSION}.1 python.1)
	sudo mkdir -p $MAGISK_PREFIX/data
	sudo chown builder:builder $MAGISK_PREFIX/data
	cp -r /data/python $MAGISK_PREFIX/data/

}

magisk_step_pre_massage() {

	# Verify that desired modules have been included:
	for module in _bz2 _curses _lzma _sqlite3 _ssl _tkinter zlib; do
		if [ ! -f "$MAGISK_PREFIX/lib/python${_MAJOR_VERSION}/lib-dynload/${module}".*.so ]; then
			magisk_error_exit "Python module library $module not built"
		fi
	done
}

mmagisk_step_create_zipscripts() {
	# Post-installation script for setting up pip.
	cat <<- POSTINST_EOF > ./postinst
	#!$MAGISK_PREFIX/bin/sh

	echo "Setting up pip..."

	# Fix historical mistake which removed bin/pip but left site-packages/pip-*.dist-info,
	# which causes ensurepip to avoid installing pip due to already existing pip install:
	if [ ! -f "$MAGISK_PREFIX/bin/pip" ]; then
	    rm -Rf ${MAGISK_PREFIX}/lib/python${_MAJOR_VERSION}/site-packages/pip-*.dist-info
	fi

	${MAGISK_PREFIX}/bin/python3 -m ensurepip --upgrade --default-pip

	exit 0
	POSTINST_EOF

	# Pre-rm script to cleanup runtime-generated files.
	cat <<- PRERM_EOF > ./prerm
	#!$MAGISK_PREFIX/bin/sh

	if [ "\$1" != "remove" ]; then
	    exit 0
	fi

	echo "Uninstalling python modules..."
	pip3 freeze 2>/dev/null | xargs pip3 uninstall -y >/dev/null 2>/dev/null
	rm -f $MAGISK_PREFIX/bin/pip $MAGISK_PREFIX/bin/pip3* $MAGISK_PREFIX/bin/easy_install $MAGISK_PREFIX/bin/easy_install-3*

	echo "Deleting remaining files from site-packages..."
	rm -Rf $MAGISK_PREFIX/lib/python${_MAJOR_VERSION}/site-packages/*

	exit 0
	PRERM_EOF

	chmod 0755 postinst prerm
}
