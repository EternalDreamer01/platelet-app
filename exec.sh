#!/bin/bash


project_name="${1:-test}"
container_id="${2:-$(docker container ls -q)}"

cmd="cd '/root/platelet/scenarios/${project_name}'"

docker exec -it "$container_id" bash
