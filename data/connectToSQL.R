# Load necessary packages
library(DBI)
library(RSQLite)

# Connect to the SQLite database
conn <- dbConnect(SQLite(), "data/csvyerine.db")

# List the tables
tables <- dbListTables(conn)
tables

# Read the table
df <- dbReadTable(conn, "mentionMatrixAll")
# Don't forget to close the connection
dbDisconnect(conn)
