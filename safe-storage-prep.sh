#!/bin/bash
# safe-storage-prep.sh prepares files and folders for storage in a non-safe environment
# e.g. cloud servers like google disk, dorpbox, ubuntu one and the like.
#
# It compresses files and subdirestories of a given directory to the tar.xz format.
# It encrypts them with gpg and creates md5 check sums of the created gpg files.
# It stores the sums for future references. 
# Only files/folders whose check sums have been modified are then uploaded/stored again.
VERSION="0.2"
CDIR="$HOME/.config/safe-storage" 	# Configuration/check-sums directory
CONF="${CDIR}/sf.conf" 				# Configuration file
#LOGF="${CDIR}/sf.log" 				# Log file
if [[ ! -d "$CDIR" ]]; then
	mkdir -p "$CDIR"
	echo "# Diretory to be prepared for safe storage." > "$CONF"
	echo "SourceDIR=" >> "$CONF"
	echo "# GPG encryption recepient." >> "$CONF"
	echo "GPGRecepient=" >> "$CONF"
#	echo "Created on $(date +%F)" > "$LOGF"
fi
# SDIR = Source directpry/The directory to be prepared for safe storage
SDIR=$(grep ^SourceDIR "$CONF" | cut -d= -f2)
GPGR=$(grep ^GPGRecepient "$CONF" | cut -d= -f2)
function usage () {
	echo -e "\nUsage:"
	echo -e "\t\e[33;1m${0##*/} [-d directory-path] [-r recepient] | [-h] | [-v]\e[0m"
	echo -e "Where:\n\t-d - Path to the folder to be safely stored"
	echo -e "\t-r - GPG encription recepient"
	echo -e "\t-v - Shows this script version."
	echo -e "\t-h - This help message"
}
function def_source () {
	if [[ "x${SDIR}" == "x" ]]; then
		if [[ -d "$1" ]]; then
			SRC=${1%/} 			# Remove trailing slash if there is one.
			SRC=${SRC//\//\\/} 	# Prepare for 'sed -i'.
			sed -i "s/^SourceDIR=/SourceDIR=${SRC}/;" "$CONF"
		fi
	fi
	SDIR=${1%/}
}
function def_recepient () {
	KEYS=$(gpg -k $1 2>/dev/null | grep pub | wc -l) 	# Number of public keys matching.
	if [[ $KEYS -eq 1 ]]; then
		if [[ "x${GPGR}" == "x" ]]; then
			sed -i "s/^GPGRecepient=/GPGRecepient=$1/;" "$CONF"
		fi
		GPGR=$1
	else
		if [[ $KEYS -eq 0 ]]; then
			echo "No public GPG key for recepient '$1'."
			echo "Run 'gpg -k' to check available keys."
			exit 3
		else
			echo "More than one public GPG keys for '$1' available."
			echo "Run 'gpg -k' or 'gpg -k $1' to check available keys."
			exit 4
		fi
	fi
}
function create_gpg () {
	echo -e "\t\t\e[31mCreating ${1}.tar.xz.gpg\e[0m"
	tar -cJf "${1}.tar.xz" "$1" 
	gpg --yes -er $2 "${1}.tar.xz"
	rm "${1}.tar.xz"
}

#--- Set options and default parameters --------------------------------
while getopts  ":d:r:hv" flag
do
    case "$flag" in
		h) usage && exit;;
		v) echo "Version ${VERSION}"; exit;;
		d) def_source "$OPTARG";;
		r) def_recepient "$OPTARG";;
	esac
done
if [[ ! -d "$SDIR" ]]; then
	if [[ x"$SDIR" = "x" ]]; then
		usage 
		echo -e "\nDiretory to be prepared for safe storage is not defined."
		echo -e "\e[33mUse the \e[33;1m-d\e[0m\e[33m option "
		echo -e "or edit the '${CONF}' configuration file.\e[0m"
		exit 1
	fi
	echo "Source directory not available or non-existent."
	exit 2
fi
if [[ x"$GPGR" = "x" ]]; then
	usage 
	echo -e "\nNo GPG recepient defined."
	echo -e "\e[33mUse the \e[33;1m-r\e[0m\e[33m option."
	echo -e "or edit the '${CONF}' configuration file.\e[0m"
	exit 5
fi

#--- Begin preparation for safe storage --------------------------------

p=$(pwd)
cd $SDIR
echo -e "\n\e[1mNote:\e[0m For new tar.xz.gpg files (if any) \nlook in \e[33m$SDIR\e[0m."
for ((t=15;--t;)) {
	echo -en "\rContinue? (Y/n) [\e[33m$t\e[0m sek] "
	read -rsn1 -t1 Q && break
}
if [[ "$Q" != "Y" && "$Q" != "y" && "$Q" != "" ]]; then
	echo -e "\rAbandoned.              "
	exit
fi
echo -e "\r                         \nWorking. This may take a few minutes.\nProcessing..."
NEWSUMS=/tmp/sfgpg.sums
echo -n "" > $NEWSUMS
for f in $(ls -1 | grep -v 'gpg$'); do 		# Exclude *gpg files.
	echo -e "\t$f"
	if [[ -d "$f" ]]; then
		NEWCHK=$(find "$f/" -type f -exec md5sum {} +|awk '{print $1}'|sort|md5sum|awk '{print $1}')
	else
		NEWCHK=$(md5sum "$f"|awk '{print $1}')
	fi
	#echo DEBUG: NEWCHK=$NEWCHK
	echo "${NEWCHK} ${f}" >> $NEWSUMS
	if [[ -e "${CDIR}/md5s" ]]; then
		# The space in " ${f}$" below is important!
		OLDCHK=$(grep " ${f}$" "${CDIR}/md5s"|cut -d" " -f1)
		#echo DEBUG: OLDCHK=$OLDCHK
		if [ "x${OLDCHK}" = x${NEWCHK} ]; then
			# The check sum has not changed. No need to crate the gpg file.
			#echo -e "\t\e[32m${f}\e[0m has not changed"
			true
		else
			if [[ -n $OLDCHK ]]; then
				# The check sum has changed. Create a gpg file.
				#echo -e "\t\e[36m${f}\e[0m has changed!"
				true
			else
				#echo -e "\t\e[34m${f}\e[0m is a new file/directory"
				true
			fi
			create_gpg $f $GPGR
		fi
	else
		create_gpg $f $GPGR
	fi
done
cp $NEWSUMS "${CDIR}/md5s"
rm $NEWSUMS
echo "Done."
cd "$p"
