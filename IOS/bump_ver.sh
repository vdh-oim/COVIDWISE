#!/usr/bin/env bash
agvtool next-version -all
echo `pwd` >> ~/lastdir
#build_number=`xcodebuild -project ExposureNotificationApp.xcodeproj -showBuildSettings | grep "CURRENT_PROJECT_VERSION" | sed 's/[ ]*CURRENT_PROJECT_VERSION = //'`
build_number=100
echo "build_number: $build_number"
sed -i.bak "s/ios-build-.*\"/ios-build-$build_number\"/" "ExposureNotificationApp/SpringML/Util/SMLLog.swift"
echo "Build number updated to #$build_number"
