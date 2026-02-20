#!/bin/bash

project_name="test"
container_id="$(docker container ls -q)"
debug_mode="gdb" 

if [[ -n "$1" && "$1" != "-" ]]; then
	debug_mode="${1,,}"
fi
if [[ -n "$2" && "$2" != "-" ]]; then
	project_name="$2"
fi
if [[ -n "$3" && "$3" != "-" ]]; then
	container_id="$3"
fi

cmd="$(grep -A1 "CMakeFiles/run_${project_name}:" data/build/CMakeFiles/run_${project_name}.dir/build.make | tail -n1)"

case "$debug_mode" in
	libs)	cmd="$(echo -n "$cmd" | sed 's/ \&\& / \&\& LD_DEBUG=libs /')" ;;
	cmdenv)	cmd="$(echo -n "$cmd" | sed 's/$/ -u Cmdenv -c General/; s/ \&\& / \&\& gdb -ex=r --args /')" ;;
	gdb)	cmd="$(echo -n "$cmd" | sed 's/ \&\& / \&\& gdb -ex=r --args /')" ;;
	*)
		echo "Invalid debug mode $debug_mode"
		exit 1
		;;
esac

docker exec -it "$container_id" bash -c "$cmd"
