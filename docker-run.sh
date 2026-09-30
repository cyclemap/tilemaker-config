

function dockerRun() {
	time docker run \
		--rm \
		--interactive \
		--tty \
		--user=$(id -u):$(id -g) \
		--volume $PWD:/data \
		--workdir /data \
		"$@"
}


