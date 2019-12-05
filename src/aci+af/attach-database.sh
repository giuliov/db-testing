#wait for the SQL Server to come up
sleep $ATTACH_WAIT
#run the script to attach the DB
/opt/mssql-tools/bin/sqlcmd -r1 -S localhost -U sa -P $SA_PASSWORD -d master -i attach-database.sql
