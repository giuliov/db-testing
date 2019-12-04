Demo code of _Use SQL Server for Linux and Docker to streamline your test and schema migration process_ session.



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
docker run -v sqldata:/sqldata --name sql1 -d --rm -e 'ACCEPT_EULA=Y' -e "SA_PASSWORD=$SA_PASSWORD" -p 1433:1433 mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
docker exec -it sql1 /bin/bash -c "ls -l /"
# mssql is the Linux user running the SQL Server process
docker exec -u 0 -it sql1 /bin/bash -c "chown mssql /sqldata"
docker exec -it sql1 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -Q "CREATE DATABASE test ON (NAME=test_data,FILENAME='/sqldata/test_data.mdf') LOG ON (NAME=test_log,FILENAME='/sqldata/test_log.ldf');"
```

Now, stop the container and show that the database survived.

```bash
docker stop sql1
docker ps
# now we see if the database survived
docker run -v sqldata:/sqldata --name sql1 -d --rm -e 'ACCEPT_EULA=Y' -e "SA_PASSWORD=$SA_PASSWORD" -p 1433:1433 mcr.microsoft.com/mssql/server:2019-GA-ubuntu-16.04
docker exec -it sql1 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -Q "SELECT name FROM sys.databases;"
docker exec -u 0 -it sql1 /bin/bash -c "ls -l /sqldata"
```

Looks like the DB files are there, but SQL hasn't take notice.
The problem is that the **master** database hasn't survived, so we must explicitly attach the DB.

```bash
docker exec -it sql1 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -Q "CREATE DATABASE test ON (NAME=test_data,FILENAME='/sqldata/test_data.mdf') LOG ON (NAME=test_log,FILENAME='/sqldata/test_log.ldf') FOR ATTACH;"
# now is good
docker exec -it sql1 /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P $SA_PASSWORD -Q "SELECT name FROM sys.databases;"
```

Clean up

```bash
docker stop sql1
docker ps
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
```

