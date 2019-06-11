#!/usr/bin/env bash
set -o xtrace
set -e

usage() {
    echo "Deploy project to Production"
    echo 'Usage: $1 artifactory address'
    echo 'Usage: $2 docker repository name'
    echo 'Usage: $3 artifactory apikey'
    echo 'Usage: $4 app image tag'
    echo 'Usage: $5 gosvc image tag'
    exit 1
}

if [ -z "$1" ] || [ -z "$2"  ] || [ -z "$3" ] || [ -z "$4"  ] || [ -z "$5"  ]; then
    usage
fi


SERVER=$1
REPOSITORY=$2
APIKEY=$3
APPIMGTAG=$4
GOSVCIMGTAG=$5

cat << EOF > /etc/docker/daemon.json
{
  "insecure-registries": ["http://${SERVER}"]
}
EOF

sudo systemctl restart docker

echo "$APIKEY" | docker login --username admin --password-stdin "$SERVER"

docker stop docker-app  && docker rm $_
docker rmi $(docker images | grep "${SERVER}/${REPOSITORY}/app" | awk '{ print $3 }') || true

docker stop docker-gosvc  && docker rm $_
docker rmi $(docker images | grep "${SERVER}/${REPOSITORY}/gosvc" | awk '{ print $3 }') || true

export GO_SERVICE=$(ifconfig $1|sed -n 2p|awk '{ print $2 }'|awk -F : '{ print $2 }')

docker run -d --name docker-app -p 80:8088 ${SERVER}/${REPOSITORY}/app:$APPIMGTAG
docker run -d --name docker-gosvc -p 3000:3000 ${SERVER}/${REPOSITORY}/gosvc:$GOSVCIMGTAG


echo "Deploy Done"
