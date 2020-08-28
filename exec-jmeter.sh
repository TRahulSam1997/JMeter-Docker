#!/bin/bash
export COMPOSE_INTERACTIVE_NO_CLI=0

echo "### Starting JMeter Container Network ###"

COUNT=${1-1}
docker build -t jmeter-base jmeter-base
docker-compose build
docker-compose up -d
docker-compose scale master=1 slave=$COUNT
SLAVE_IP=$(docker inspect -f '{{.Name}} {{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' $(docker ps -aq) | grep slave | awk -F' ' '{print $2}' | tr '\n' ',' | sed 's/.$//')
WDIR=`docker exec master /bin/pwd | tr -d '\r'`
mkdir -p results

for filename in scripts/*.jmx; do
     "for loop"
    NAME=$(basename $filename)
    NAME="${NAME%.*}"
    eval "docker cp $filename master:$WDIR/scripts/"
    eval "docker exec master /bin/bash -c 'mkdir $NAME && cd $NAME && ../bin/jmeter -n -t ../$filename -R$SLAVE_IP'"
    eval "docker cp master:$WDIR/$NAME results/"
done

docker-compose stop && docker-compose rm -f

echo "### End Of JMeter Container Network ###"