#!/bin/bash

set -e #exit on failure
set -x #print out commands

date=$(date --iso-8601)
name=${NAME:-cyclemaps}
input=$name.osm.pbf
output=$name-$date.pmtiles
published=$name.pmtiles

exec &> >(tee >(\
	sed \
		--unbuffered \
		--expression=s//\\$'\n'/g \
	|
	egrep
		--line-buffered \
		--invert \
		'^(Store size|(osm|shp): finalizing z6 tile|z.*, writing tile |^  *[0-9]*% \|\| |^ *$)' \
	>>"logs/update-$name.log"
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
	echo updating:  started at $(date --iso-8601=seconds)
	dockerRun \
		openmaptiles/openmaptiles-tools:7.1 \
		osmupdate --verbose $input $input-new.osm.pbf
	#mv --force $input $input-old.osm.pbf
	mv --force $input-new.osm.pbf $input
	echo updating:  done at $(date --iso-8601=seconds)
}

function makeTiles() {
	echo make tiles:  started at $(date --iso-8601=seconds)
	dockerRun \
		ghcr.io/systemed/tilemaker:master \
		$input \
		--store store-$name \
		--output $output \
		--config config-cyclemaps.json \
		--process process-cyclemaps.lua

	dockerRun \
		protomaps/go-pmtiles \
		cluster --no-deduplication $output
	echo make tiles:  done at $(date --iso-8601=seconds)
}




echo 'to update:  for tag in openmaptiles/openmaptiles-tools:7.1 ghcr.io/systemed/tilemaker:master protomaps/go-pmtiles; do docker pull $tag; done'

#tilemaker/get-landcover.sh
#tilemaker/get-coastline.sh
#rm --force {landcover,coastline}/*.zip

#updateInput
makeTiles
if [ -x publish.sh ]; then ./publish.sh $output $published; fi


