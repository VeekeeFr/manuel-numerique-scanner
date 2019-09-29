#!/bin/bash

SCRIPTFULLNAME=`realpath $0`
SCRIPTPATH=`dirname ${SCRIPTFULLNAME}`
SCRIPTNAME=`basename ${SCRIPTFULLNAME}`

function usage
{
	echo "Usage:"
	echo "${0} -book <book-id> [-force]"
	exit ${1}
}

JQ_RELEASE=1.6
BOOKID=
FORCE_DOWNLOAD=false

while [ $# -gt 0 ]
do
	case "$1" in
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
	echo "	-> Found book #${1}"
	BOOK_TAR="${SCRIPTPATH}/${1}.tar.gz"
	BOOK_DIR="${SCRIPTPATH}/${1}"
	if [ ${FORCE_DOWNLOAD} ] && [ -f ${BOOK_TAR} ]
	then
		rm -rf ${BOOK_TAR}
	fi
	if [ ! -f ${BOOK_TAR} ]
	then
		echo "		-> Storage folder: ${BOOK_DIR}"
		
		if [ -d ${BOOK_DIR} ]
		then
			rm -rf ${BOOK_DIR}
		fi
		mkdir -p ${BOOK_DIR}

		curl -sS -q -o ${BOOK_DIR}/content.json "https://d.calameo.com/3.0.0/book.php?callback=_jsonBook&bkcode=${BOOKID}"
		sed -i -e "s#_jsonBook(\(.*\))#\1#g" ${BOOK_DIR}/content.json
		BOOK_COVER=`cat ${BOOK_DIR}/content.json | ${SCRIPTPATH}/jq '.content.url.poster' | awk -F'"' '{ print $2 }'`
		BOOK_TITLE=`cat ${BOOK_DIR}/content.json | ${SCRIPTPATH}/jq '.content.name' | awk -F'"' '{ print $2 }'`
		BOOK_IDENTIFIER=`cat ${BOOK_DIR}/content.json | ${SCRIPTPATH}/jq '.content.id' | awk -F'"' '{ print $2 }'`
		BOOK_KEY=`cat ${BOOK_DIR}/content.json | ${SCRIPTPATH}/jq '.content.key' | awk -F'"' '{ print $2 }'`
		BOOK_PAGES=`cat ${BOOK_DIR}/content.json | ${SCRIPTPATH}/jq '.content.document.pages'`
		rm -f ${BOOK_DIR}/content.json

		echo "		# Found book: ${BOOK_TITLE} (pages: ${BOOK_PAGES})"

		echo "		# Processing cover"
		curl -sS -q -o ${BOOK_DIR}/cover.png https:${BOOK_COVER} || echo "			! ERROR"
		page=0
		while [ ${page} -le ${BOOK_PAGES} ]
		do
			page=$((page+1))
			echo "		# Processing page: ${page}"
			curl -sS -q -o ${BOOK_DIR}/page_${page}.svg https://p.calameoassets.com/${BOOK_KEY}/p${page}.svgz || echo "			! ERROR"
		done

		echo "		-> Building archive"
		cp ${SCRIPTPATH}/index_calameo.html ${BOOK_DIR}/index.html
		cat ${BOOK_DIR}/index.html | sed "s#{{ title }}#${BOOK_TITLE}#g" > ${BOOK_DIR}/index.html.tmp && mv ${BOOK_DIR}/index.html.tmp ${BOOK_DIR}/index.html
		cat ${BOOK_DIR}/index.html | sed "s#{{ pagecount }}#${BOOK_PAGES}#g" > ${BOOK_DIR}/index.html.tmp && mv ${BOOK_DIR}/index.html.tmp ${BOOK_DIR}/index.html
		cd ${BOOK_DIR}
		tar czvf ${BOOK_TAR} *
		cd -
		echo "		-> Generated archive: ${BOOK_TAR}"
		rm -rf ${BOOK_DIR}
	else
		echo "		[SKIPPED]"
	fi
}

if [ "x${BOOKID}" == "x" ]
then
	echo "Book ID is mandatory!"
	exit 1
fi

if [ ! -f ${SCRIPTPATH}/jq ]
then
	echo "Downloading JQ ${JQ_RELEASE}"
	curl -sS -L -q -o ${SCRIPTPATH}/jq https://github.com/stedolan/jq/releases/download/jq-${JQ_RELEASE}/jq-linux64
	chmod +x ${SCRIPTPATH}/jq
fi

echo "Scanning ${BOOKID}"
curl -sS -q -o /dev/null "https://d.calameo.com/3.0.0/book.php?callback=_jsonBook&bkcode=${BOOKID}" && processBook ${BOOKID}

echo "eop."