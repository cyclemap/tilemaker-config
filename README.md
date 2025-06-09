
This is the tilemaker config script used to update cyclemaps.org

## dependencies

* [tilemaker](https://github.com/systemed/tilemaker)
* [protomaps pmtiles](https://github.com/protomaps/go-pmtiles)

## main scripts

* [update.sh](update.sh)
* client side codebase:  https://github.com/cyclemap/cyclemaps

## other related links

* [maputnik editor](https://maplibre.org/maputnik/)
  * **you have to use maplibre's maputnik editor to get pmtiles** (or `pmtiles serve --cors=* --port=8080 cyclemaps.pmtiles`  [ticket](https://github.com/maplibre/maputnik/issues/807))
  * data sources -> openmaptiles v3 -> tilejsonurl -> `pmtiles://https://tileserver.cyclemaps.org/cyclemaps.pmtiles`
  * open -> load from url -> `https://cyclemaps.org/style.json`
  * layers tree view on the left -> cycleway-unpaved -> click the "eye" visibility icon (show/hide)
  * layers tree view on the left -> cycleway-unknown -> click the "eye" visibility icon (show/hide)
  * layers tree view on the left -> cycleway-paved -> click the "eye" visibility icon (show/hide)
  * (for debugging data:  view -> map dropdown.  change to inspect)

