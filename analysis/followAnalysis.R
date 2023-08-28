# Load necessary packages
library(DBI)
library(RSQLite)
library(igraph)
library(multinet)
library(ggplot2)
library(ggraph)
library(devtools)
library(tidyverse)
library(RColorBrewer)
#devtools::install_github("manlius/muxViz")
library(muxViz)
# Connect to the SQLite database
conn <- dbConnect(SQLite(), "/Users/harunpirim/Documents/GitHub/multilayer_polarization/data/csvyerine.db")
#conn <- dbConnect(SQLite(), "../data/csvyerine.db")
#read final table
finalTableWithAdditions <- read_csv("/Users/harunpirim/Documents/GitHub/multilayer_polarization/data/finalTable.csv", col_types = cols(.default = "c"))
#finalTableWithAdditions <- read_csv("../data/finalTable.csv", col_types = cols(.default = "c"))

# List the tables
tables <- dbListTables(conn)
# Read the table
df <- dbReadTable(conn, "followingMatrixAll")
df1<-df[,-1]
View(df1)
# Remove 'x' from column names
names(df1) <- gsub("X", "", names(df1))
# Convert dataframe to matrix
df_mat <- data.matrix(df1)
rownames(df_mat) <- colnames(df_mat)
#graph from adj matrix
g_fol <- graph_from_adjacency_matrix(df_mat,"undirected")
tkplot(g_fol)
df_mat["5558312","5558312"] #controlling self loop, yes it is there
length(t(unique(finalTableWithAdditions[1]))) # unique colors
#assign colors to parties
color <- c()
for (i in 1:length(t(unique(finalTableWithAdditions[1])))) {
if (finalTableWithAdditions[i, "party"] == "Republican") {
color <- append(color, 0)
} else {
color <- append(color, 1)
}
}
names(color) <- pull(unique(finalTableWithAdditions[,1]))
color
V(g_fol)$name
names(color)
# Initialize color vector C
C <- character(length(V(g_fol)$name))
# Iterate over V
for (i in seq_along(V(g_fol)$name)) {
name <- V(g_fol)$name[i]
matching_index <- match(name, names(color))
if (!is.na(matching_index)) {
C[i] <- color[matching_index]
} else {
C[i] <- "2"
}
}
C
V(g_fol)$name[1]
V(g_fol)$name[2]
match(V(g_fol)$name[1],names(color))
match(V(g_fol)$name[2],names(color))
color[25]
# Replace values using ifelse()
C <- ifelse(C == "1", "Dem", ifelse(C == "0", "Rep", ifelse(C == "2", "Ind", C)))
#plot with labels
V(g_fol)$labels <- C
# Get unique values from C
unique_values <- unique(C)
# Generate unique color codes based on the number of unique values
num_colors <- length(unique_values)
color_palette <- brewer.pal(num_colors, "Set3")
# Create a color vector based on the unique values in C
color_vector <- color_palette[match(C, unique_values)]
tkplot(g_fol, vertex.label=V(g_fol)$labels, vertex.color=color_vector)
save.image("~/Documents/Research/CSS/layers/multilayer_polarization-main/data/layers.RData")
savehistory("~/Documents/Research/CSS/layers/multilayer_polarization-main/data/layers.Rhistory")
tkplot(g_fol, vertex.label=V(g_fol)$labels, vertex.color=color_vector)
