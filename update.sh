#!/bin/bash

set -e #exit on failure

if [ -e config.sh ]; then
	source config.sh
fi
source docker-run.sh

updateInput=${UPDATE_INPUT:-yes}
date=$(date --rfc-3339=date)
name=${NAME:-cyclemaps}
input=$name.osm.pbf
inputMinimumSize=${INPUT_MINIMUM_SIZE:-85} #this file is sometimes too small ( this is the error that gets ignored: osmconvert Error: write error. ), we should error out when it's too small
output=$name-$date.pmtiles
published=$name.pmtiles
image=${IMAGE:-ghcr.io/systemed/tilemaker:master}
storeDirectory=${STORE_DIRECTORY:-$PWD/tmp}
tilemakerParameters=${TILEMAKER_PARAMETERS:-}

# wget https://planet.openstreetmap.org/pbf/planet-latest.osm.pbf && \mv {planet-latest,cyclemaps}.osm.pbf && updatecyclemaps

exec &> >(tee >(\
	sed \
		--unbuffered \
		--expression=s//\\$'\n'/g \
	|
	egrep \
		--line-buffered \
		--invert \
		'^(Store size|(osm|shp): finalizing z6 tile|z.*, writing tile |^  *[0-9]*% \|\| |^ *$)' \
	>>"logs/update-$name.log"
))

function checkInput() {
	filename=$1
	size=$(stat --format=%s $filename)
	minimum=$(($inputMinimumSize*1024**3))
	if [ $size -lt $minimum ]; then
		echo "$filename:  file smaller than expected:  ($size < $minimum)"
		exit 1
	fi
}

function updateInput() {
	echo updating:  started at $(date --rfc-3339=seconds)
	dockerRun \
		openmaptiles/openmaptiles-tools:7.2 \
		osmupdate --verbose $input $input-new.osm.pbf
	checkInput "$input-new.osm.pbf"
	mv --force $input-new.osm.pbf $input
	
	# changes the BLOCK SIZE of the pbf file.  osmconvert, used by osmupdate won't let you set this value ( pb__blockM ) without recompiling
	# tilemaker notices this in tilemaker/src/pbf_processor.cpp:  filesize / blocks.size() > 1000000
	# takes about an hour and saves some amount of time
	dockerRun \
		openmaptiles/openmaptiles-tools:7.2 \
		osmium cat -f pbf $input -o $input-new.osm.pbf
	checkInput "$input-new.osm.pbf"
	mv --force $input-new.osm.pbf $input
	echo updating:  done at $(date --rfc-3339=seconds)
}

function makeTiles() {
	echo make tiles:  started at $(date --rfc-3339=seconds)
	echo tilemaker version $(docker inspect $image |
		jq --raw-output '.[0].Config.Labels |
			(."org.opencontainers.image.created"[:10] + " " + ."org.opencontainers.image.revision"[:7])')
	#note on memory:  --store needs to exist unless you have somewhere around 256gb of ram
	#even with --store, you need approximately the memory defined by dockerRun
	dockerRun \
		--volume $storeDirectory:/tmp/tilemaker \
		$image \
		$input \
		--store /tmp/tilemaker/store-$name \
		--output $output \
		--config config.json \
		--process process.lua \
		$tilemakerParameters
	
	wc --bytes $output
	ls --size --human-readable $output

	dockerRun \
		protomaps/go-pmtiles \
		cluster --no-deduplication $output
	
	(
		wc --bytes $output
		ls --size --human-readable $output
	) |tee --append logs/file-sizes.txt

	echo make tiles:  done at $(date --rfc-3339=seconds)
}



echo '==='
echo "to update:  for tag in openmaptiles/openmaptiles-tools:7.2 $image protomaps/go-pmtiles; do docker pull \$tag; done"
set -x #print out commands

#tilemaker/get-landcover.sh
#tilemaker/get-coastline.sh
#rm --force {landcover,coastline}/*.zip

if [ -x process.sh ]; then ./process.sh; fi
if [ "$updateInput" == "yes" ]; then updateInput; fi
checkInput "$input"
makeTiles
if [ -x publish.sh ]; then ./publish.sh $output $published; fi


echo done at $(date --rfc-3339=seconds)


