$SA_PASSWORD = Read-Host -Prompt "SQL Server SA password"
New-Alias azuredatastudio "C:\Program Files\Azure Data Studio\azuredatastudio.exe"

### Hello World!
docker pull hello-world
docker run -it --rm --name hello hello-world
# cleanup
docker image rm hello-world


### custom image
docker build . -t custom:v1
docker run -it --rm --name bash0 custom:v1
docker ps
# cleanup
docker image rm bash:4.4 custom:v1


### SQL Server
docker pull mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
docker run --name sql0 --rm -e 'ACCEPT_EULA=Y' -e "SA_PASSWORD=$SA_PASSWORD" -p 1433:1433 mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
# wait 30 seconds
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
# it is possible to have more than one process in a Container
docker exec -it sql0 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD
SELECT name FROM sys.databases;
GO
quit
docker stop sql0
docker ps
