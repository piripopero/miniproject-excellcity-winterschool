#!/bin/bash

set -e

deleteVolumes=false

# Procesar flags de línea de comandos
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --clean)
      deleteVolumes=true
      shift
      ;;
    -*|--*)
      echo "Usage: cmd [--clean]"
      exit 1
      ;;
    *)
      break
      ;;
  esac
done

ORION="http://orion:1026/version"
IOT_AGENT="http://iot-agent:4041/version"
MINTAKA="http://mintaka:8080/info"
CONTEXT="http://context/context.jsonld"

dockerCmd="docker compose"
if (( $# == 2 )); then
    dockerCmd="docker-compose"
fi

stoppingContainers () {
	CONTAINERS=$(docker ps --filter "label=org.fiware=excellcity" -aq)
	if [[ -n $CONTAINERS ]]; then 
		echo "Stopping containers"
		docker rm -f $CONTAINERS 
	fi

	if [ "$deleteVolumes" = true ]; then
        VOLUMES=$(docker volume ls --filter "label=org.fiware=excellcity" -q)
		echo -e "\033[0;31mRemoving Docker volumes. Warning: Any data not mapped to a local directory will be lost.\033[0m"
			
		# Confirmación del usuario
		read -p $'\033[0;31mAre you sure you want to delete the volumes? This will result in data loss if the volumes are not mapped. Type \'y\' to continue: \033[0m' confirm
		if [[ $confirm != "y" ]]; then
			echo "Operation aborted. Volumes were not deleted."
			exit 1
		fi
		
		echo "Removing  volumes -> $deleteVolumes -> $VOLUMES"

        if [[ -n $VOLUMES ]]; then 
            echo "Removing old volumes"
            docker volume rm $VOLUMES 
        fi
    fi
	NETWORKS=$(docker network ls  --filter "label=org.fiware=excellcity" -q) 
	if [[ -n $NETWORKS ]]; then 
		echo "Removing  networks"
		docker network rm $NETWORKS 
	fi
}

displayServices () {
	echo ""
	docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter name="$1"
	echo ""
}

waitForMongo () {
	echo -e "\n⏳ Waiting for \033[1mMongoDB\033[0m to be available\n"
	while ! [ `docker inspect --format='{{.State.Health.Status}}' mongo-db` == "healthy" ]
	do 
		sleep 1
	done
}

waitForIoTAgent () {
	echo -e "\n⏳ Waiting for \033[1;36mIoT-Agent\033[0m to be available\n"
	while ! [ `docker inspect --format='{{.State.Health.Status}}' fiware-iot-agent` == "healthy" ]
	do
		echo -e "\nIoT Agent HTTP state: ${response} (waiting for 200)"
		pause 3
		getHeartbeat "${IOT_AGENT}"
	done
}
waitForUseCaseContext () {
	echo -e "\n⏳ Waiting for user \033[1m@context\033[0m to be available\n"
	getHeartbeat "${CONTEXT}"
	while [ "${response}" -eq 000 ]
	do
		echo -e "\n@context HTTP state: ${response} (waiting for 200)"
		pause 3
		getHeartbeat "${CONTEXT}"
	done
}

addDatabaseIndex () {
	printf "Adding appropriate \033[1mMongoDB\033[0m indexes for \033[1;34mOrion\033[0m  ..."
	docker exec  mongo-db mongo --eval '
	conn = new Mongo();db.createCollection("orion");
	db = conn.getDB("orion");
	db.createCollection("entities");
	db.entities.createIndex({"_id.servicePath": 1, "_id.id": 1, "_id.type": 1}, {unique: true});
	db.entities.createIndex({"_id.type": 1});
	db.entities.createIndex({"_id.id": 1});' > /dev/null

	docker exec  mongo-db mongo --eval '
	conn = new Mongo();db.createCollection("orion-excellcity");
	db = conn.getDB("orion-excellcity");
	db.createCollection("entities");
	db.entities.createIndex({"_id.servicePath": 1, "_id.id": 1, "_id.type": 1}, {unique: true});
	db.entities.createIndex({"_id.type": 1});
	db.entities.createIndex({"_id.id": 1});' > /dev/null
	echo -e " \033[1;32mdone\033[0m"
}

addIoTDatabaseIndex () {
	printf "Adding appropriate \033[1mMongoDB\033[0m indexes for \033[1;36mIoT-Agent\033[0m  ..."
	docker exec  mongo-db mongo --eval '
	conn = new Mongo();
	db = conn.getDB("iotagentjson");
	db.getCollectionNames().forEach(c=>db[c].drop());
	db.createCollection("devices");
	db.devices.createIndex({"_id.service": 1, "_id.id": 1, "_id.type": 1});
	db.devices.createIndex({"_id.type": 1});
	db.devices.createIndex({"_id.id": 1});
	db.createCollection("groups");
	db.groups.createIndex({"_id.resource": 1, "_id.apikey": 1, "_id.service": 1});
	db.groups.createIndex({"_id.type": 1});' > /dev/null
	echo -e " \033[1;32mdone\033[0m"
}
pause(){
	printf " "
	count="$1"
	[ "$count" -gt 59 ] && printf "Waiting one minute " || printf " Waiting a few seconds ";
	while [ "$count" -gt 0 ]
	do
		printf "."
		sleep 3
		count=$((count - 3))
	done
	echo ""
}
waitForOrion () {
	echo -e "\n⏳ Waiting for \033[1;34mOrion-LD\033[0m to be available\n"
	
	while ! [ `docker inspect --format='{{.State.Health.Status}}' fiware-orion` == "healthy" ]
	do
		echo -e "\nContext Broker HTTP state: ${response} (waiting for 200)"
		pause 6
		getHeartbeat "${ORION}"
	done
}
waitForMintaka () {
	echo -e "\n⏳ Waiting for \033[1;34mMintaka\033[0m to be available\n"
	
	while ! [ `docker inspect --format='{{.State.Health.Status}}' mintaka` == "healthy" ]
	do
		echo -e "\nMintaka HTTP state: ${response} (waiting for 200)"
		pause 6
		getHeartbeat "${MINTAKA}"
	done
}

getHeartbeat(){
	eval "response=$(docker run --network fiware-deployment --rm quay.io/curl/curl:${CURL_VERSION} -s -o /dev/null -w "%{http_code}" "$1")"
}

export $(cat .env | grep "#" -v)
stoppingContainers
echo -e "Starting containers:  \033[1;34mOrion\033[0m, \033[1;36mIoT-Agent\033[0m, a linked data \033[1mContext\033[0m, a \033[1mTimescaleDB\033[0m and a \033[1mMongoDB\033[0m database."
echo -e "- \033[1;34mOrion\033[0m is the context broker"
echo -e "- \033[1;36mIoT-Agent\033[0m is configured for the JSON Protocol"
echo ""
${dockerCmd} -f docker-compose.yml up -d --remove-orphans 
displayServices "orion|fiware|mintaka|mongo|timescale|node-red|grafana"
waitForMongo
addDatabaseIndex
addIoTDatabaseIndex
waitForUseCaseContext
waitForOrion
waitForIoTAgent
waitForMintaka

echo -e "\033[1;34mOrion\033[0m is now running and exposed on localhost"

# Llamada al script de importación de datos estáticos
./import_static_data.sh