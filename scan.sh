#!/bin/bash

SCRIPTFULLNAME=`realpath $0`
SCRIPTPATH=`dirname ${SCRIPTFULLNAME}`
SCRIPTNAME=`basename ${SCRIPTFULLNAME}`

function usage
{
	echo "Usage:"
	echo "${0} [-cat <cat-id>] [-book <book-id>] [-force]"
	exit ${1}
}

BOOKCAT=$(seq 1 9)
BOOKID=$(seq 1000 4000)
BORDAS_FILLING="N2JiNDg5MjEwODg3MWI3MDA5NzkxNmNiOWU3MjJlZWY2OTBjNmRkNDZkNjNlMzY1ZjUwYzg2NWNiZDg2ZDk0MjFkNzQ2M2NkMzg4NGE5ZDg4ODU1YmZjZDQ3ZGE4YTk5MDQ0MGUzYzU"
FORCE_DOWNLOAD=false

while [ $# -gt 0 ]
do
	case "$1" in
		-c | --c | -cat | --cat )
			shift
			BOOKCAT="${1}"
			;;
		-b | --b | -book | --book )
			shift
			BOOKID="${1}"
			;;
		-force | --force )
			FORCE_DOWNLOAD=true
			;;
		-? | --? | -h | --h | -help | --help )
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
	if [ ${FORCE_DOWNLOAD} ] && [ -f ${BOOK_TAR} ]
	then
		rm -rf ${BOOK_TAR}
	fi
	if [ ! -f ${BOOK_TAR} ]
	then
		echo "		-> Storage folder: ${BOOK_DIR}"
		mkdir -p ${BOOK_DIR}
		curl -q  -o ${BOOK_DIR}/content.txt https://biblio.manuel-numerique.com/epubs/web/${BORDAS_FILLING}/BORDAS/bibliomanuels/distrib_gp/${1}/${2}/${3}/online/OEBPS/content.opf
		BOOK_TITLE=`cat ${BOOK_DIR}/content.txt | grep "<dc:title id=\"title1\">" | awk -F'>' '{ print $2 }' | awk -F'<' '{ print $1 }'`
		BOOK_IDENTIFIER=`cat ${BOOK_DIR}/content.txt | grep "<dc:identifier " | awk -F'>' '{ print $2 }' | awk -F'<' '{ print $1 }'`
		BOOK_PAGELIST=`cat ${BOOK_DIR}/content.txt | grep "\.xhtml" | grep "Page" | awk -F'href="' '{ print $2 }' | awk -F'"' '{ print $1 }' | tr '\n' ',' | sed 's#,#","#g'`
		if [ "x${BOOK_PAGELIST}" != "x" ]
		then
			BOOK_PAGELIST="\"${BOOK_PAGELIST:0:-2}"
			for file in `cat ${BOOK_DIR}/content.txt | grep "<item " | awk -F'href=' '{ print $2 }' | awk -F'"' '{ print $2 }'`
			do
				RESSOURCE_FOLDER=`dirname $file`
				RESSOURCE_NAME=`basename $file`
				mkdir -p ${BOOK_DIR}/${RESSOURCE_FOLDER}
				echo "		# Processing file: ${RESSOURCE_NAME} (target: ${BOOK_DIR}/${RESSOURCE_FOLDER})"
				curl -q -o ${BOOK_DIR}/${RESSOURCE_FOLDER}/${RESSOURCE_NAME} https://biblio.manuel-numerique.com/epubs/web/${BORDAS_FILLING}/BORDAS/bibliomanuels/distrib_gp/${1}/${2}/${3}/online/OEBPS/${file} || echo "			! ERROR"
			done

			echo "		-> Downloading epub"
			curl -q -o ${BOOK_DIR}/book.epub http://dl.manuel-numerique.com//BORDAS/bibliomanuels/distrib_gp/${1}/${2}/${3}/${3}-1_2-${BOOK_IDENTIFIER}.epub
		else
			echo "Failed! Book seems to have gotten away..."
		fi

		echo "		-> Building archive"
		cp ${SCRIPTPATH}/index.html ${BOOK_DIR}
		cat ${BOOK_DIR}/index.html | sed "s#{{ title }}#${BOOK_TITLE}#g" > ${BOOK_DIR}/index.html.tmp && mv ${BOOK_DIR}/index.html.tmp ${BOOK_DIR}/index.html
		cat ${BOOK_DIR}/index.html | sed "s#{{ pagelist }}#${BOOK_PAGELIST}#g" > ${BOOK_DIR}/index.html.tmp && mv ${BOOK_DIR}/index.html.tmp ${BOOK_DIR}/index.html
		cd ${BOOK_DIR}
		tar czvf ${BOOK_TAR} *
		cd -
		echo "		-> Generated archive: ${BOOK_TAR}"
		rm -rf ${BOOK_DIR}
	else
		echo "		[SKIPPED]"
	fi
}

for bookcat in ${BOOKCAT}
do
	for book in ${BOOKID}
	do
		echo "Scanning ${book}"
		curl -q -o /dev/null https://biblio.manuel-numerique.com/epubs/web/${BORDAS_FILLING}/BORDAS/bibliomanuels/distrib_gp/1/${bookcat}/${book}/online/OEBPS/content.opf  && processBook 1 ${bookcat} ${book}
	done
done

echo "eop."