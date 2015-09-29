#!/bin/bash

CONTAINER_NAME="wait-for-mysql-test-container"
SQL_FILE="test-queries.sql"
MY_ROOT_PASSWORD="testroot"
MY_USERNAME="test"
MY_PASSWORD="test"
MY_DATABASE="test"

docker kill $CONTAINER_NAME
docker rm $CONTAINER_NAME

docker run \
  -e MYSQL_ROOT_PASSWORD=$MY_ROOT_PASSWORD \
  -e MYSQL_USER=$MY_USERNAME \
  -e MYSQL_PASSWORD=$MY_PASSWORD \
  -e MYSQL_DATABASE=$MY_DATABASE \
  --name=$CONTAINER_NAME \
  -P -d mysql:5.6

MY_HOST="localhost"
MY_PORT=`docker inspect -f '{{(index (index .NetworkSettings.Ports "3306/tcp") 0).HostPort}}' ${CONTAINER_NAME}`

echo "host: ${MY_HOST}"
echo "port: ${MY_PORT}"
echo "user: ${MY_USERNAME}"
echo "pass: ${MY_PASSWORD}"
echo "  db: ${MY_DATABASE}"

coffee src/index.coffee \
  --query="SELECT 1" \
  --host=$MY_HOST \
  --port=$MY_PORT \
  --username=$MY_USERNAME \
  --password=$MY_PASSWORD \
  --database=$MY_DATABASE \
  --connect-timeout=100 \
  --total-timeout=10000

EXIT_CODE=$?
echo "Exit code: ${EXIT_CODE}"

docker kill $CONTAINER_NAME
docker rm $CONTAINER_NAME

