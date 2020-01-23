New-Alias azuredatastudio "C:\Program Files\Azure Data Studio\azuredatastudio.exe"


### Hello World!
docker pull hello-world
docker run -it --rm --name hello hello-world
# cleanup
docker image rm hello-world


### custom image
cd /src/github.com/giuliov/db-testing/src/custom-image
code . # describe the Dockerfile and shell script
docker images ls
docker build . --tag custom:v1
docker images ls
docker run -it --rm --name bash0 custom:v1
docker ps
# cleanup
docker image rm bash:4.4 custom:v1


### SQL Server
docker pull mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
$SA_PASSWORD = Read-Host -Prompt "SQL Server SA password"
docker run --name sql0 --rm -e 'ACCEPT_EULA=Y' -e "SA_PASSWORD=$SA_PASSWORD" -p 1433:1433 mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
# see the messages and wait about 30 seconds
azuredatastudio
# connect to localhost
# new query
SELECT @@VERSION
CREATE DATABASE test
# refresh locahost panel

### see what happens after we stop the container
docker stop sql0
docker ps
docker run --name sql0 -d --rm -e 'ACCEPT_EULA=Y' -e "SA_PASSWORD=$SA_PASSWORD" -p 1433:1433 mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
docker ps
# switch to azuredatastudio
# connect to localhost
# database is GONE!


### Volumes
#Create a volume, mount and create the database on the volume.
docker volume create sqldata
docker run -v sqldata:/var/opt/mssql --name sql1 -d --rm -e 'ACCEPT_EULA=Y' -e "SA_PASSWORD=$SA_PASSWORD" -p 1433:1433 mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
# switch to azuredatastudio
# connect to localhost
# CREATE DATABASE test
#Now, stop the container and show that the database survived.
docker stop sql1
docker ps
# now we see if the database survived
docker run -v sqldata:/var/opt/mssql --name sql1 -d --rm -e 'ACCEPT_EULA=Y' -e "SA_PASSWORD=$SA_PASSWORD" -p 1433:1433 mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
# switch to azuredatastudio
# connect to localhost
# shows that it is possible to have more than one process in a Container
docker exec -u 0 -it sql1 /bin/bash -c "ls -l /var/opt/mssql/data"
#Clean up
docker stop sql1
docker ps
docker volume rm sqldata
docker volume ls

