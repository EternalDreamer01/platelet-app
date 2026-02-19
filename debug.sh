#!/bin/sh


project_name="${1:-test}"
container_id="${2:-$(docker container ls -q)}"

cmd="$(grep -A1 "CMakeFiles/run_${project_name}:" data/build/CMakeFiles/run_${project_name}.dir/build.make | tail -n1)"

if [ "$1" = "libs" ]; then
	cmd="$(echo -n "$cmd" | sed 's/ \&\& / \&\& LD_DEBUG=libs /')"
else
	cmd="$(echo -n "$cmd" | sed 's/ \&\& / \&\& gdb -ex=r --args /')"
fi

docker exec -it "$container_id" bash -c "$cmd"
