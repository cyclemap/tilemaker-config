#!/bin/bash

set -e #exit on failure

updateInput=${UPDATE_INPUT:-yes}
date=$(date --rfc-3339=date)
name=${NAME:-cyclemaps}
input=$name.osm.pbf
output=$name-$date.pmtiles
published=$name.pmtiles

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

function dockerRun() {
	#TODO:  blkio-weight works without device-read-bps and without device-write-bps???
	#TODO:  if not, /dev/sdc lookup should be automatic
	#TODO:  bps is bytes:  400 megabytes / second is my laughably old drive throughput
	#sdc (root) / sdb (docker):  Samsung SSD 850 EVO 1TB:  430 megabytes / second write
	#sda (bak):  Samsung SSD 840 EVO 1TB:  360 megabytes / second write
	time docker run \
		--memory='21g' \
		--memory-swap='32g' \
		--cpus=4 \
		--blkio-weight=100 \
		--device-read-bps=/dev/sdb:300mb \
		--device-write-bps=/dev/sdb:300mb \
		--device-read-bps=/dev/sdc:300mb \
		--device-write-bps=/dev/sdc:300mb \
		--rm \
		--interactive \
		--tty \
		--user=$(id -u):$(id -g) \
		--volume $PWD:/data \
		--workdir /data \
		"$@"
}

function updateInput() {
	echo updating:  started at $(date --rfc-3339=seconds)
	dockerRun \
		openmaptiles/openmaptiles-tools:7.2 \
		osmupdate --verbose $input $input-new.osm.pbf
	#mv --force $input $input-old.osm.pbf
	mv --force $input-new.osm.pbf $input
	echo updating:  done at $(date --rfc-3339=seconds)
}

function makeTiles() {
	echo make tiles:  started at $(date --rfc-3339=seconds)
	echo tilemaker version $(docker inspect ghcr.io/systemed/tilemaker:master |
		jq --raw-output '.[0].Config.Labels |
			(."org.opencontainers.image.created"[:10] + " " + ."org.opencontainers.image.revision"[:7])')
	#note on memory:  --store needs to exist unless you have somewhere around 256gb of ram
	#even with --store, you need somewhere around 32-40gb of memory with swap
	dockerRun \
		--volume /mnt/docker/tilemaker:/tmp/tilemaker \
		ghcr.io/systemed/tilemaker:master \
		$input \
		--store /tmp/tilemaker/store-$name \
		--output $output \
		--config config.json \
		--process process.lua
	
	wc --bytes $output
	ls --size --human-readable $output

	dockerRun \
		protomaps/go-pmtiles \
		cluster --no-deduplication $output
	
	wc --bytes $output
	ls --size --human-readable $output

	echo make tiles:  done at $(date --rfc-3339=seconds)
}



echo '==='
echo 'to update:  for tag in openmaptiles/openmaptiles-tools:7.2 ghcr.io/systemed/tilemaker:master protomaps/go-pmtiles; do docker pull $tag; done'
set -x #print out commands

#tilemaker/get-landcover.sh
#tilemaker/get-coastline.sh
#rm --force {landcover,coastline}/*.zip

if [ -x process.sh ]; then ./process.sh; fi
if [ "$updateInput" == "yes" ]; then updateInput; fi
makeTiles
if [ -x publish.sh ]; then ./publish.sh $output $published; fi


echo done at $(date --rfc-3339=seconds)


