##### May 21, 2016

## Reset everything
```
docker stop imply
docker rm imply
docker run -p 8081-8110:8081-8110 -p 8200:8200 -p 9095:9095 -d --name imply imply/imply:$implyversion
docker ps
```

```
d57829ded7f7        imply/imply:        "bin/supervise -c con"   8 seconds ago       Up 7 seconds        1527/tcp, 0.0.0.0:8081-8110->8081-8110/tcp, 0.0.0.0:8200->8200/tcp, 2181/tcp, 0.0.0.0:9095->9095/tcp   imply
```

### Run Import and Ingestion Shell Script
*use: ./import.sh filename index*

##### Restart Docker
docker ps -a
docker start imply
sleep 15

##### Display IP address
ip=$(docker-machine ip default)

##### copy generated logs
cp ~/Nitrous/roguecartel-3340/cf-data-185360/logs.json .
echo "...copied files from logs.json"

filename=$1
index=$2

echo $filename
echo $ip

cp logs.json $filename

# Import the file into Docker container
docker cp $filename imply:root/imply-1.1.1/quickstart/$filename
echo "imported datasource"  $filename

docker cp $index imply:root/imply-1.1.1/quickstart/$index
echo "imported index" $index

# Run index
echo "posting the index:" $index
docker exec -it imply bin/post-index-task -f quickstart/$index
echo "completed posting index: " $index

# Open Browser

echo "open pivot"
open "http://$ip:9095/pivot#"

## Generate new ratelimit-logs.json

* import using same script
* confirm timestamps in the interval
* checked the Druid console: https://www.dropbox.com/s/bexpa5vjvbm6knw/Screenshot%202016-05-21%2018.17.19.png?dl=0



expect to see data in that time range in pivot but it's not there:

