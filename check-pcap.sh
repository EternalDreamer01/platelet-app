#!/bin/bash

project_name="${1:-test}"
container_id="${2:-$(docker container ls -q)}"

docker exec -it "$container_id" sh -c 'find /root /opt /app -name "*.pcap" | grep -v "/opt/artery/extern/inet/tests/unit/pcap/"'
