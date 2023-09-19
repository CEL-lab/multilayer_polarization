#multiplex analysis of democratic affiliation only
#required libraries
library(DBI)
library(RSQLite)
library(igraph)
library(multinet)#multiplex analysis
library(ggplot2)
library(ggraph)
library(devtools)
library(tidyverse)
library(RColorBrewer)
#devtools::install_github("manlius/muxViz")
library(muxViz)#multiplex visualization
# Connect to the SQLite database
conn <- dbConnect(SQLite(), "/Users/harunpirim/Documents/GitHub/multilayer_polarization/data/csvyerine2.db")
#read meta table
metadata <- dbReadTable(conn, "metadata")
# List all tables
tables <- dbListTables(conn)
# List supervised tables
sup_tables <- tables[tables %>% str_detect("^sup")]
#List unsupervised tables
unsup_tables <- tables[tables %>% str_detect("^unsup")]
# Randomly select n males
n <- nrow(subset(metadata,region=='south'))
set.seed(123)  # Setting a seed for reproducibility
north_labels <- sample(which(metadata['region'] == 'north'), n)
#nodes that have democrat label
#north_labels <- which(metadata['finalSex']=='M')

#construct layers from tables from adjacency matrices
construct_layers_north <- function(type = "sup") {
  layers <- list()  # Create an empty list to store data frames and matrices
  for (i in 1:length(get(paste0(type, "_tables")))) {
    df <- dbReadTable(conn, get(paste0(type, "_tables"))[i])
    df <- df[, -1]  # Remove the first column
    df <- df %>%
      rename_with(~gsub("^X", "", .), starts_with("X")) %>% slice(north_labels) %>%  select(north_labels) %>% 
      as.matrix()
    # Assign the result to a list element
    layers[[paste0("layer", i)]] <- df
  }
  return(layers)
}
#construct supervised layers
layers_sup_north <- construct_layers_north("sup")
#layers_sup is a list of adjacency matrices
ilayers_sup_north <- lapply(layers_sup_north, function(adj_matrix) {
  graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
})
#construct unsupervised layers
layers_unsup_north <- construct_layers_north("unsup")
ilayers_unsup_north <- lapply(layers_unsup_north, function(adj_matrix) {
  graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
})
#create empty multiplex for supervised
multiplex_sup_north <- ml_empty()
#add igraph layers
for(i in 1:length(ilayers_sup_north)){
  if(length(E(ilayers_sup_north[[i]])!=0))
    add_igraph_layer_ml(multiplex_sup_north,ilayers_sup_north[[i]],sup_tables[i])
}

#create empty multiplex for unsupervised
multiplex_unsup_north <- ml_empty()
#add igraph layers
for(i in 1:length(ilayers_unsup_north)){
  if(length(E(ilayers_unsup_north[[i]])!=0))
    add_igraph_layer_ml(multiplex_unsup_north,ilayers_unsup_north[[i]],unsup_tables[i])
}
#plot
plot(multiplex_sup_north, vertex.labels = north_labels, vertex.labels.cex = 0.3, vertex.color = 'red', vertex.size = 0.05)
dev.off()
plot(multiplex_unsup, vertex.labels = north_labels, vertex.labels.cex = 0.3, vertex.color = 'red', vertex.size = 0.05)
dev.off()
#summary statistics for layers
summary(multiplex_sup_north)
summary(multiplex_unsup_north)
