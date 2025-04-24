#!/bin/sh

current_dir=$(pwd)
theming_dir="/OpenCloud/Resources/Theming"
theme=$1

if [ -d "$theming_dir" ]; then
	git submodule init
	git submodule update

	rename 's/current./theme./' $current_dir$theming_dir/*.*
	mv $current_dir$theming_dir/theme.$theme $current_dir$theming_dir/current.$theme

	cp $current_dir$theming_dir/current*/*.png $current_dir$theming_dir/
	cp $current_dir$theming_dir/current*/*.json $current_dir$theming_dir/Branding.json

	fastlane generate_appicon

	gomplate --file ./tools/gomplate/Branding.plist.tmpl \
	--context config=$current_dir$theming_dir/Branding.json \
	--out $current_dir$theming_dir/Branding.plist
else
    echo "Directory $theming_dir does not exist. Please execute this script in the root path of the ios repository."
fi