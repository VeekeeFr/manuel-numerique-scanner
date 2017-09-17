#!/bin/bash

SCRIPTPATH=`dirname $0`
SCRIPTNAME=`basename $0`

function usage
{
	echo "Usage:"
	echo "$0 [-book <book-id>]"
	exit ${1}
}

BOOKCAT=$(seq 1 4)
BOOKID=$(seq 1000 4000)

while [ $# -gt 0 ]
do
	case "$1" in
		-b | --b | -book | --book )
			shift
			BOOKID="${1}"
			;;
		-? | --? | -h | --h | -help | --help )
			echo "aaaaaaaaaaaaaaaaaa"
			usage "0"
			;;
		*)
			echo "ERROR: Unknown argument '$1'!"
			usage "1"
			;;
	esac
	shift
done

function processBook
{
	echo "	-> Found book #${3} (${1}/${2})"
	BOOK_TAR="${SCRIPTPATH}/${1}_${2}_${3}.tar.gz"
	BOOK_DIR="${SCRIPTPATH}/${1}/${2}/${3}"
	if [ ! -f ${BOOK_TAR} ]
	then
		echo "		-> Storage folder: ${BOOK_DIR}"
		mkdir -p ${BOOK_DIR}
		wget -q http://biblio.manuel-numerique.com/epubs/BORDAS/bibliomanuels/distrib_gp/${1}/${2}/${3}/online/OEBPS/content.opf -O${BOOK_DIR}/content.txt
		for file in `cat ${BOOK_DIR}/content.txt | grep "<item " | awk -F'href=' '{ print $2 }' | awk -F'"' '{ print $2 }'`
		do
			RESSOURCE_FOLDER=`dirname $file`
			RESSOURCE_NAME=`basename $file`
			mkdir -p ${BOOK_DIR}/${RESSOURCE_FOLDER}
			echo "		# Processing file: ${RESSOURCE_NAME} (target: ${BOOK_DIR}/${RESSOURCE_FOLDER})"
			wget -q http://biblio.manuel-numerique.com/epubs/BORDAS/bibliomanuels/distrib_gp/${1}/${2}/${3}/online/OEBPS/${file} -O${BOOK_DIR}/${RESSOURCE_FOLDER}/${RESSOURCE_NAME} || echo "			! ERROR"
		done
		cd ${BOOK_DIR} && tar czvf ${SCRIPTPATH}/${1}_${2}_${3}.tar.gz * && cd -
		rf -rf ${BOOK_DIR}
	else
		echo "		[SKIPPED]"
	fi
}

for bookcat in ${BOOKCAT}
do
	echo "${bookcat}"
	for book in ${BOOKID}
	do
		echo "Scanning ${book}"
		wget -q http://biblio.manuel-numerique.com/epubs/BORDAS/bibliomanuels/distrib_gp/1/${bookcat}/${book}/online/OEBPS/content.opf -O/dev/null && processBook 1 ${bookcat} ${book}
	done
done

echo "eop."