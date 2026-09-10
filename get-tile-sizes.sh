#!/bin/bash

file=$1

tiles=https://tileserver.cyclemaps.org/$file

latitude=38.9
longitude=-77.1

IFS=',' read -ra expectedSizes <<< $(tail -n1 logs/tile-sizes.csv)
expectedSizes=( "${expectedSizes[@]:1}" )

exec 3>>logs/tile-sizes.csv

echo tile sizes
echo z nineTileSizes changeFromExpected
>&3 echo -n "$file"
for((z=0;z<=3;z++)); do >&3 echo -n ,0; done
for((z=4;z<=14;z++)); do
	read -ra columns <<< $(awk '{
		z=$1
		
		PI=3.1415926535
		latitude=$2*PI/180
		longitude=$3*PI/180
		
		x=(PI + longitude) / (2*PI)
		yAngle = PI/4 + latitude/2
		y=(PI - log(sin(yAngle)/cos(yAngle))) / (2*PI)
		
		print z, int(x * 2**z), int(y * 2**z)
	}' <<< "$z $latitude $longitude")

	xOriginal=${columns[1]}
	yOriginal=${columns[2]}

	totalSize=0
	for((yDiff=-1;yDiff<=1;yDiff++)); do
		y=$(($yOriginal+$yDiff))
		for((xDiff=-1;xDiff<=1;xDiff++)); do
			x=$(($xOriginal+$xDiff))
			size=$(pmtiles tile $tiles $z $x $y |wc -c)
			totalSize=$(($totalSize+$size))
		done
	done
	>&3 echo -n ",$totalSize"
	echo $z $totalSize $(($totalSize - ${expectedSizes[$z]}))
done

>&3 echo


