# zero2hero data usage
# required libraries
library(DBI)
library(RSQLite)
library(igraph)
library(multinet) # multiplex analysis
library(ggplot2)
library(ggraph)
library(devtools)
library(tidyverse)
library(RColorBrewer)
# devtools::install_github("manlius/muxViz")
library(muxViz) # multiplex visualization

# Connect to the SQLite database
conn <- dbConnect(SQLite(), "./data/csvyerine2.db")

# List all tables
tables <- dbListTables(conn)

# reat all sqlite tables to df
read_sqlite <- function(conn, table_name) {
    df <- dbReadTable(conn, table_name)
    df <- df[, -1] # Remove the first column
    df <- df %>%
        rename_with(~ gsub("^X", "", .), starts_with("X")) %>%
        as.matrix()
    return(df)
}

matrix_list <- list()
for (i in 2:length(tables)) {
    matrix_list[[tables[i]]] <- read_sqlite(conn, tables[i])
}

# metadata
metadata <- dbReadTable(conn, "metadata")

add_edges_from_matrix <- function(g, adj_matrix) {
    for (i in 1:nrow(adj_matrix)) {
        for (j in 1:ncol(adj_matrix)) {
            if (adj_matrix[i, j] == 1) {
                g <- add_edges(g, c(i, j))
            }
        }
    }
    return(g)
}

# List to store graphs
graph_list <- list()

for (i in 1:length(matrix_list)) {
    # Create an empty graph
    g <- graph.empty(n = nrow(metadata), directed = FALSE)

    # Add node attributes
    V(g)$finalParty <- metadata$finalParty
    V(g)$finalRegion <- metadata$finalRegion
    V(g)$finalSex <- metadata$finalSex
    V(g)$region <- metadata$region
    V(g)$finalCandidate <- metadata$finalCandidate
    V(g)$finalName <- metadata$finalName

    # Add edges from matrix
    g <- add_edges_from_matrix(g, matrix_list[[i]])

    # Store the graph in graph_list with the corresponding name
    graph_list[[names(matrix_list)[i]]] <- g
}

# some plot denemeleri
plot_graph <- function(g) {
    ggraph(g, layout = "kk") +
        geom_edge_link() +
        geom_node_point() +
        theme_graph()
}

plot(graph_list[["sup_econ"]])
plot(graph_list[["sup_econ"]], vertex.label = V(g)$finalName)

g <- graph_list[["sup_econ"]]
V(g)$color <- ifelse(V(g)$finalParty == "Democrat", "blue", "red")

plot(g, vertex.label = V(g)$OFFICE2)

# supervised graphs
sup_graph_list <- graph_list[grepl("^sup", names(graph_list))]
# unsupervised graphs
unsup_graph_list <- graph_list[grepl("^unsup", names(graph_list))]
