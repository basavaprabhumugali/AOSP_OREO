#!/bin/bash
#Copyright © 2018, Qualcomm Innovation Center, Inc. All rights reserved.  Confidential and proprietary.
#Copyright © 2018, Intrinsyc Technologies Corporation.

UNDER='\e[4m'
RED='\e[31;1m'
GREEN='\e[32;1m'
YELLOW='\e[33;1m'
BLUE='\e[34;1m'
MAGENTA='\e[35;1m'
CYAN='\e[36;1m'
WHITE='\e[37;1m'
ENDCOLOR='\e[0m'
ITCVER="O_v1.0"
WORKDIR=`pwd`
CAFTAG="LA.UM.6.3.r4-04500-sdm845.0"
#CAFTAG="LA.UM.8.3.r1-05800-sdm845.0"
BUILDROOT="${WORKDIR}/SDA845_Open-Q_845_Android-${ITCVER}"
PATCH_DIR="${WORKDIR}/patches"
DB_PRODUCT_STRING="Open-Q 845 HDK Development Kit"

function download_CAF_CODE() {
# Do repo sanity test
if [ $? -eq 0 ]
then
	echo "Downloading code please wait.."
#	repo init -q -u git://gitmirror/cm/download/codeaurora/sas-manifest-NEW.git -m LA.UM.8.3.r1-05800-sdm845.0.xml 

	repo init -q -u git://gitmirror/cm/download/codeaurora/sas-manifest-NEW.git -m LA.UM.6.3.r4-04500-sdm845.0.xml
# 	repo init -q -u git://gitmirror/cm/download/codeaurora/sas-manifest-NEW.git -m LA.UM.6.3.r4-04500-sdm845.0.xml
#	repo init -q -u git://codeaurora.org/platform/manifest.git -b release -m ${CAFTAG}.xml
	repo sync -q -c -j 4 --no-tags --no-clone-bundle
	if [ $? -eq 0 ]
	then
		echo -e "$GREEN Downloading done..$ENDCOLOR"
	else
		echo -e "$RED!!!Error Downloading code!!!$ENDCOLOR"
	fi
else
	echo "repo tool problem, make sure you have setup your build environment"
	echo "1) http://source.android.com/source/initializing.html"
	echo "2) http://source.android.com/source/downloading.html (Installing Repo Section Only)"
	exit -1
fi
}

#  Function to check result for failures
check_result() {
if [ $? -ne 0 ]
then
	echo
	echo -e "$RED FAIL: Current working dir:$(pwd) $ENDCOLOR"
	echo
	exit 1
else
	echo -e "$GREEN DONE! $ENDCOLOR"
fi
}

# Function to autoapply patches to CAF code
apply_android_patches()
{

	echo "Applying patches ..."
	if [ ! -e $PATCH_DIR ]
	then
		echo -e "$RED $PATCH_DIR : Not Found $ENDCOLOR"
		return
	fi
	cd $PATCH_DIR
	patch_root_dir="$PATCH_DIR"
	android_patch_list=$(find . -type f -name "*.patch" | sort) &&
	for android_patch in $android_patch_list; do
		android_project=$(dirname $android_patch)
		echo -e "$YELLOW   applying patches on $android_project ... $ENDCOLOR"
		cd $BUILDROOT/$android_project
		if [ $? -ne 0 ]; then
			echo -e "$RED $android_project does not exist in BUILDROOT:$BUILDROOT $ENDCOLOR"
			exit 1
		fi
		git am --3way $patch_root_dir/$android_patch
		check_result
	done
}

#  Function to check whether host utilities exists
check_program() {
for cmd in "$@"
do
	which ${cmd} > /dev/null 2>&1
	if [ $? -ne 0 ]
	then
		echo
		echo -e "$RED Cannot find command \"${cmd}\" $ENDCOLOR"
		echo
		exit 1
	fi
done
}


#Main Script starts here
#Note: Check necessary program for installation
echo
echo -e "$CYAN Product                   : $DB_PRODUCT_STRING $ENDCOLOR"
echo -e "$MAGENTA Intrinsyc Release Version : $ITCVER $ENDCOLOR"
echo -e "$MAGENTA WorkDir                   : $WORKDIR $ENDCOLOR"
echo -e "$MAGENTA Build Root                : $BUILDROOT $ENDCOLOR"
echo -e "$MAGENTA Patch Dir                 : $PATCH_DIR $ENDCOLOR"
echo -e "$MAGENTA CodeAurora TAG            : $CAFTAG $ENDCOLOR"
echo -n "Checking necessary program for installation......"
echo
check_program tar repo git patch
if [ -e $BUILDROOT ]
then
	cd $BUILDROOT
else
	mkdir $BUILDROOT
	cd $BUILDROOT
fi

#1 Download code
download_CAF_CODE
cd $BUILDROOT

#2 Apply Open-Q 845 HDK Development Kit Patches
apply_android_patches

#3 Extract the proprietary objs
cd $BUILDROOT
echo -e "$YELLOW   Extracting proprietary binary package to $BUILDROOT ... $ENDCOLOR"
tar -xzvf ../proprietary.tar.gz -C vendor/qcom/

#4 Build
echo -e "$YELLOW   Building Source code from $BUILDROOT ... $ENDCOLOR"
if [[ -z "${BUILD_NUMBER}" ]]; then export BUILD_NUMBER=$(date +%m%d%H%M); fi
ITC_ID=Open-Q_845_${ITCVER} ./build.sh sdm845 -j $(nproc) -s 0 $@
