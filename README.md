Demo code of _Use SQL Server for Linux and Docker to streamline your test and schema migration process_ session.


## Demos

[Volatile volume](#volatile-volume)  
[Permanent volume](#permanent-volume)  
[SQL Create script](#sql-create-script)  
[Restore backup and mask data](#restore-backup-and-mask-data)  
[In the cloud](#in-the-cloud)  
[Container Instance + File share](#container-instance--file-share)  
[Pipeline](#pipeline)  



## Prerequisites

The demos require an Azure subscription and an Azure DevOps organisation.
You need to have correct values for the following environment variables.

```bash
# replace with a value that suits you
RESOURCE_GROUP=dbtesting
RESOURCE_LOCATION=westeurope
SA_PASSWORD=******
ATTACH_WAIT=10s
ACR_SERVER=******.azurecr.io
ACR_USER=******
ACR_PASSWD=********
STORAGEACCOUNT_NAME=******
STORAGEACCOUNT_KEY=******
AZP_URL=https://dev.azure.com/******
AZP_TOKEN=******
```

## Volatile volume

Shows that container filesystem is volatile.
Set a variable in the shell for `sa` password, e.g. `SA_PASSWORD=P@ssw0rdToUseFor_sa`.

Get official SQL Server image and create a database.

```bash
docker pull mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
docker run --name sql0 -d --rm -e 'ACCEPT_EULA=Y' -e "SA_PASSWORD=$SA_PASSWORD" -p 1433:1433 mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
docker ps
docker exec -it sql0 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD
SELECT @@VERSION, @@SERVERNAME;
SELECT name FROM sys.databases;
GO
CREATE DATABASE test;
GO
SELECT name FROM sys.databases;
GO
quit
```

Now we restart the container and see that the database is gone.

```bash
docker stop sql0
docker ps
docker run --name sql0 -d --rm -e 'ACCEPT_EULA=Y' -e "SA_PASSWORD=$SA_PASSWORD" -p 1433:1433 mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
docker exec -it sql0 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -Q "SELECT name FROM sys.databases;"
# test is gone
```

Clean up

```bash
docker stop sql0
docker ps
```



## Permanent volume

To persist the database we must use a volume.

Create a volume, mount and create the database on the volume.

```bash
docker volume create sqldata
docker run -v sqldata:/var/opt/mssql --name sql1 -d --rm -e 'ACCEPT_EULA=Y' -e "SA_PASSWORD=$SA_PASSWORD" -p 1433:1433 mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
docker exec -it sql1 /bin/bash -c "ls -l /var/opt/mssql/data"
docker exec -it sql1 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -Q "CREATE DATABASE test;"
```

Now, stop the container and show that the database survived.

```bash
docker stop sql1
docker ps
# now we see if the database survived
docker run -v sqldata:/var/opt/mssql --name sql1 -d --rm -e 'ACCEPT_EULA=Y' -e "SA_PASSWORD=$SA_PASSWORD" -p 1433:1433 mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
docker exec -it sql1 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -Q "SELECT name FROM sys.databases;"
docker exec -u 0 -it sql1 /bin/bash -c "ls -l /var/opt/mssql/data"
```

Clean up

```bash
docker stop sql1
docker ps
docker volume rm sqldata
docker volume list
```



## SQL Create script

This demo shows how to run a SQL script at start.
The script is `import-script/setup.sql` and creates a `Products` table in a new `demo` database.
Furthermore is shows how to load data from a CSV file using the **bcp** tool.

```bash
cd import-script
docker build . -t mssql-launch-script:v1

docker run --name sql2 -d --rm -e 'ACCEPT_EULA=Y' -e "SA_PASSWORD=$SA_PASSWORD" -p 1433:1433 mssql-launch-script:v1
docker exec -it sql2 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -Q "SELECT name FROM sys.databases;"
docker exec -it sql2 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -d demo -Q "SELECT * FROM Products;"
```

Clean up

```bash
docker stop sql2
docker ps
cd ..
```



## Restore backup and mask data

This time we restore the famous **pubs** database from a backup, using multi-pass Dockerfile.
In the first pass, we inject the `.bak` file and restore it.
In the second pass we pick the restored `.mdf` and `.ldf` files.

```bash
cd bake-database
docker build . -t mssql-pubs:v1
```

```bash
docker run --name sql3 --rm -e 'ACCEPT_EULA=Y' -e "SA_PASSWORD=$SA_PASSWORD" -p 1433:1433 mssql-pubs:v1
docker exec -it sql3 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -Q "SELECT name FROM sys.databases;"
docker exec -it sql3 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -d pubs -Q "SELECT * FROM employee;"
```

As you see the launch script executes the `bake-database/clean-data.sql` script. It trivially replaces employee surnames with asterisks (`*`).

Clean up

```bash
docker stop sql3
docker ps
cd ..
```



## In the cloud

We continue from the previous step, deploying the image in Azure.
This demo requires a few Azure resources and environment variables.

```bash
# replace with a value that suits you
RESOURCE_GROUP=dbtesting
RESOURCE_LOCATION=westeurope
cd azure-resources
az group create --name $RESOURCE_GROUP --location $RESOURCE_LOCATION
az group deployment create --resource-group $RESOURCE_GROUP --template-file template.json -o json --query "properties.outputs"
```

The template creates the Container Registry and the Azure File shares required later.
Set the environment variables grabbing values from the output.

```bash
ACR_SERVER=******.azurecr.io
ACR_USER=******
ACR_PASSWD=********
STORAGEACCOUNT_NAME=******
STORAGEACCOUNT_KEY=******
```

Add a verbose tag to the image and push it to the registry.

```bash
# add tag to match future registry location
docker tag mssql-pubs:v1 $ACR_SERVER/sql-demo/linux/mssql-pubs:v1
# check we are using the right subscription
az account list -o table
az account set --subscription ********
# this retrieves a token for docker
az acr login --name $ACR_USER
# finally
docker push $ACR_SERVER/sql-demo/linux/mssql-pubs:v1
```

Finally create the ACI and run it.
> NOTE we use the admin account

```bash
az container create --resource-group $RESOURCE_GROUP --name ${RESOURCE_GROUP}-pubs --location $RESOURCE_LOCATION --cpu 2 --memory 2 --image $ACR_SERVER/sql-demo/linux/mssql-pubs:v1 --registry-login-server $ACR_SERVER --registry-username $ACR_USER --registry-password $ACR_PASSWD --dns-name-label ${RESOURCE_GROUP}-pubs --ports 1433 --protocol TCP --environment-variables ACCEPT_EULA=Y SA_PASSWORD=$SA_PASSWORD ATTACH_WAIT=30s
```

The command will take a couple of minutes to create the VM and pull the image from the registry.

Look in the Portal the actions then the logs.

Now connect using Azure Data Studio or similar.

Clean up

```bash
az container delete --resource-group $RESOURCE_GROUP --name ${RESOURCE_GROUP}-pubs --yes
cd ..
```



## Container Instance + File share

Now, we will mount an existing database, could be TB-sized, from a share.
Looks like mounting the share on `/var/opt/mssql` crashes SQL, so we will use a different directory i.e. `/sqldata`.

First step, we upload the **pubs** database files (`.mdf` and `.ldf`) to an Azure File share.

```bash
az storage file upload-batch --account-name $STORAGEACCOUNT_NAME --account-key $STORAGEACCOUNT_KEY --destination database --source azure-resources/data/
```

Then we create the image, upload to Registry and start it.

```bash
cd aci+af/Sql
docker build . -t $ACR_SERVER/sql-demo/linux/mssql-attach-pubs:v1
az acr login --name $ACR_USER
docker push $ACR_SERVER/sql-demo/linux/mssql-attach-pubs:v1
cd ..
eval "echo \"$(cat deploy.yaml)\"" > _temp.yaml
az container create --resource-group $RESOURCE_GROUP --file _temp.yaml -o tsv
```

Note the trick to replace environment variable values in the YAML file.
The command will take a couple of minutes to create the VM and pull the image from the registry.

Look in the Portal the actions then the logs.

Now connect using Azure Data Studio or similar.
Works? Good.

Next demo is adding a trivial sidecar running some simple query.

```bash
cd aci+af/Sidecar
docker build . -t $ACR_SERVER/sql-demo/linux/mssql-tests:v1
az acr login --name $ACR_USER
docker push $ACR_SERVER/sql-demo/linux/mssql-tests:v1
cd ..
eval "echo \"$(cat deploy-2.yaml)\"" > _temp-2.yaml
az container create --resource-group $RESOURCE_GROUP --file _temp-2.yaml -o tsv
```

You see the query in the logs?
```bash
az container logs --resource-group $RESOURCE_GROUP --name ${RESOURCE_GROUP}-tests --container-name mssql-tests
```

Clean up

```bash
rm _temp.yaml
az container delete --resource-group $RESOURCE_GROUP --name ${RESOURCE_GROUP}-attach-pubs --yes
rm _temp-2.yaml
az container delete --resource-group $RESOURCE_GROUP --name ${RESOURCE_GROUP}-tests --yes
cd ..
```



## Pipeline

This last demo is more interesting and realistic.
We have the now usual SQL instance running in Azure, mounting a database from Azure Files; this time the sidecar container is an Azure Pipelines agent running tests.

Build the agent image and push it to the Registry.

```
cd pipeline/agent
docker build . -t $ACR_SERVER/sql-demo/linux/azp-agent:v1
az acr login --name $ACR_USER
docker push $ACR_SERVER/sql-demo/linux/azp-agent:v1
```

Deploy the containers couple.

```
cd ..
eval "echo \"$(cat deploy-agent.yaml)\"" > _temp-agent.yaml
az container create --resource-group $RESOURCE_GROUP --file _temp-agent.yaml -o tsv
```

Now kick-off the pipeline in Azure Pipelines and look at the _Tests_ tab.

Clean up

```bash
rm _temp-agent.yaml
az container delete --resource-group $RESOURCE_GROUP --name ${RESOURCE_GROUP}-agent --yes
cd ..
```