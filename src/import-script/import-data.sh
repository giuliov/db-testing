echo "Import data script started..."

#wait for the SQL Server to come up
sleep 15s

echo "Wait is over, hope SQL is ready..."

echo "Running sqlcmd setup.sql..."
#run the setup script to create the DB and the schema in the DB
/opt/mssql-tools/bin/sqlcmd -r1 -S localhost -U sa -P $SA_PASSWORD -d master -i setup.sql

echo "Running bcp Products.csv..."
#import the data from the csv file
/opt/mssql-tools/bin/bcp demo.dbo.Products in "/sqlcode/Products.csv" -c -t',' -S localhost -U sa -P $SA_PASSWORD
