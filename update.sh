#!/bin/bash
set -x

set -e #exit on failure

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
	mv --force $input $input-old.osm.pbf
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
		--config tilemaker/config.json \
		--process tilemaker/process.lua
	#	--config config-cyclemaps.json \
	#	--process process-cyclemaps.lua

	dockerRun \
		protomaps/go-pmtiles \
		cluster --no-deduplication $output
	echo make tiles:  done at $(date)
}

function publish() {
	mv $output ~/web/html/map
	ln --symbolic --force $output ~/web/html/map/cyclemaps-large.pmtiles
}



echo 'to update:  for tag in openmaptiles/openmaptiles-tools:7.1 ghcr.io/systemed/tilemaker:master protomaps/go-pmtiles; do docker pull $tag; done'

date=$(date --iso-8601)
input=cyclemaps-large.osm.pbf
output=cyclemaps-large-$date.pmtiles

#tilemaker/get-landcover.sh
#tilemaker/get-coastline.sh

#updateInput
makeTiles
publish



