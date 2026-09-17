#!/bin/bash

set -o errexit
set -o pipefail
set -o nounset


if ! [ -f "virginia-latest.osm.pbf" ]; then
	curl --silent --show-error --follow --fail --output=virginia-latest.osm.pbf \
		https://download.geofabrik.de/north-america/us/virginia-latest.osm.pbf
fi

if ! [ -f "nova.osm.pbf" ]; then
	docker-run \
		openmaptiles/openmaptiles-tools:7.2 \
		osmium extract \
		--bbox -77.381,38.521,-77.065,38.981 \
		--output nova.osm.pbf \
		virginia-latest.osm.pbf
fi

