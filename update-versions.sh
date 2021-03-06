#/bin/bash

module_path="modules";
tmux_path="../termux-packages";
package_path="$tmux_path/packages";

mb_dir=$(pwd);
cd $tmux_path;
git pull;
cd $mb_dir;

add_date() {
    printf '%s %s\n' "$(date)" "$line";
}

add_divider() {
    echo '-----------------------------';
}

add_date >> .update.log;
add_divider >> .update.log;

function version_gt() { test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1"; }

for module in $(find "$module_path/" -maxdepth 1 -type d -name "*" -printf "%P\n"); do
	echo "Checking module $module..";
	if ! [[ -d "$package_path/$module" ]]; then
		echo "Could not find package with name $module";
		continue;
	fi

	module_build_path="$module_path/$module/build.sh";

	source "$module_build_path" 2>/dev/null;
	if [ -z "$MAGISK_MODULE_VERSION" ]; then
		continue;
	fi
	module_version="$MAGISK_MODULE_VERSION";
	module_srcurl="$MAGISK_MODULE_SRCURL";
	module_sha256="$MAGISK_MODULE_SHA256";

	source "$package_path/$module/build.sh" 2>/dev/null;
	if [ -z "$TERMUX_PKG_VERSION" ]; then
		continue;
	fi
	package_version="$TERMUX_PKG_VERSION";
	package_srcurl="$TERMUX_PKG_SRCURL";
	package_sha256="$TERMUX_PKG_SHA256";

	if version_gt "$package_version" "$module_version" ; then
		echo -e "Magisk module $module can be updated from $module_version to $package_version ($package_srcurl)";
		#perl -i.bak -pe "s/MAGISK_MODULE_VERSION=[\"]*"$module_version[\"]*"/MAGISK_MODULE_VERSION=\""$package_version\""/g" "$module_build_path";
		#cat "$module_build_path";
		perl -i.bak -pe 's|(MAGISK_MODULE_VERSION=[\"]*)[a-zA-Z0-9.]+([\"]*\n)|${1}'$package_version'\2|' "$module_build_path"
		#perl -i.bak -pe 's|(MAGISK_MODULE_SRCURL=[\"]*)[^\"]+([\"]*\n)|${1}'$package_srcurl'\2|' "$module_build_path";
		perl -i.bak -pe 's|(MAGISK_MODULE_SHA256=[\"]*)[^\"]+([\"]*\n)|${1}'$package_sha256'\2|' "$module_build_path";	
		#perl -i.bak -pe "s/MAGISK_MODULE_SHA256=[\"]*"$module_sha256[\"]*"/MAGISK_MODULE_SHA256=\""$package_sha256\""/g" "$module_build_path";
		source "$module_build_path" 2>/dev/null;
		new_module_version="$MAGISK_MODULE_VERSION";
		if [[ "$new_module_version" == "$package_version" ]]; then
			out="Module $module updated to new version $new_module_version";
			echo $out;
			echo $out >> .update.log;
		else
			out="Module $module encountered an error!";
			echo $out;
			echo $out >> .update.log;
			exit 0;
		fi

	fi

	#echo "perl -pe 's:(\bMAGISK_MODULE_VERSION=\s+)$module_version:$1$package_version:' $module_build_path;";
	#
	# | while read line; do
	#	if [[ "$line" == TERMUX_PKG_VERSION* ]] ; then
	#		#version=$(cat $("$line") | sed 's/=/ /g' | awk '{printf $2}');
	#		echo $version;
	#	fi
	#done
done

echo "" >> .update.log;
