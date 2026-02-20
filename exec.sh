#!/bin/bash


project_name="${2:-test}"
container_id="${3:-$(docker container ls -q)}"

cmd="$1"

if [ -z "$cmd" ]; then
	docker exec -it "$container_id" bash
else
	docker exec -it "$container_id" bash -c "$cmd"
fi