MAGISK_MODULE_HOMEPAGE=https://curl.haxx.se/docs/caextract.html
MAGISK_MODULE_DESCRIPTION="Common CA certificates"
MAGISK_MODULE_LICENSE="GPL-2.0"
MAGISK_MODULE_VERSION=20201016
MAGISK_MODULE_SRCURL=https://curl.haxx.se/ca/cacert.pem
# If the checksum has changed, it may be time to update the package version:
MAGISK_MODULE_SHA256=bb28d145ed1a4ee67253d8ddb11268069c9dafe3db25a9eee654974c4e43eee5
MAGISK_MODULE_SKIP_SRC_EXTRACT=true
MAGISK_MODULE_PLATFORM_INDEPENDENT=true

magisk_step_make_install() {
	local CERTDIR=$MAGISK_PREFIX/etc/tls
	local CERTFILE=$CERTDIR/cert.pem

	mkdir -p $CERTDIR

	magisk_download $MAGISK_MODULE_SRCURL \
		$CERTFILE \
		$MAGISK_MODULE_SHA256
	touch $CERTFILE

	# Build java keystore which is split out into a ca-certificates-java subpackage:
	local KEYUTIL_JAR=$MAGISK_MODULE_CACHEDIR/keyutil-0.4.0.jar
	magisk_download \
		https://github.com/use-sparingly/keyutil/releases/download/0.4.0/keyutil-0.4.0.jar \
		$KEYUTIL_JAR \
		18f1d2c82839d84949b1ad015343c509e81ef678c24db6112acc6c0761314610

	local JAVA_KEYSTORE_DIR=$PREFIX/lib/jvm/openjdk-9/lib/security
	mkdir -p $JAVA_KEYSTORE_DIR

	java -jar $KEYUTIL_JAR \
		--import \
		--new-keystore $JAVA_KEYSTORE_DIR/jssecacerts \
		--password changeit \
		--force-new-overwrite \
		--import-pem-file $CERTFILE
}
