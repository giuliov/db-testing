using System;
using Xunit;
using System.Data;
using Microsoft.Data.SqlClient;

namespace db_tests
{
    public class EmployeeTests
    {
        [Fact]
        public void ReadTenRecordsFromEmployeeTable_Succeeds()
        {
            // see https://weblog.west-wind.com/posts/2018/Feb/18/Accessing-Configuration-in-NET-Core-Test-Projects
            // for a good, scalable way of accessing Configuration
            // this hack is just enough for demo
            var saPassword = Environment.GetEnvironmentVariable("SA_PASSWORD");

            string connectionString = $"Server=localhost;Database=pubs;User=sa;Password={saPassword}";
            string queryString = "SELECT TOP 10 fname,minit,lname FROM employee";
            int count = 0;
            using (var connection = new SqlConnection(connectionString))
            {
                SqlCommand command = new SqlCommand(queryString, connection);
                connection.Open();
                using (SqlDataReader reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        count++;
                    }
                }
            }

            Assert.Equal(10, count);
        }
    }
}
