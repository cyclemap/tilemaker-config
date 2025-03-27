#!/bin/bash

set -e #exit on failure
set -x #print out commands

exec &> >(tee >(\
	cat \
	>>"logs/update.log"
))

function dockerRun() {
	time docker run \
		--rm \
		-it \
		--user=$(id -u):$(id -g) \
		--volume $PWD:/data \
		--workdir /data \
		"$@"
}

function updateInput() {
	echo updating:  started at $(date)
	dockerRun \
		openmaptiles/openmaptiles-tools:7.1 \
		osmupdate --verbose $input $input-new.osm.pbf
	#mv --force $input $input-old.osm.pbf
	mv --force $input-new.osm.pbf $input
	echo updating:  done at $(date)
}

function makeTiles() {
	echo make tiles:  started at $(date)
	echo untested
	dockerRun \
		ghcr.io/systemed/tilemaker:master \
		$input \
		--store store \
		--output $output \
		--config config-cyclemaps.json \
		--process process-cyclemaps.lua
	#	--config tilemaker/config.json \
	#	--process tilemaker/process.lua

	dockerRun \
		protomaps/go-pmtiles \
		cluster --no-deduplication $output
	echo make tiles:  done at $(date)
}




echo 'to update:  for tag in openmaptiles/openmaptiles-tools:7.1 ghcr.io/systemed/tilemaker:master protomaps/go-pmtiles; do docker pull $tag; done'

date=$(date --iso-8601)
name=${NAME:-cyclemaps-large}
input=$name.osm.pbf
output=$name-$date.pmtiles
published=$name.pmtiles

#tilemaker/get-landcover.sh
#tilemaker/get-coastline.sh
#rm --force {landcover,coastline}/*.zip

updateInput
makeTiles
if [ -x publish.sh ]; then ./publish.sh $output $published; fi


