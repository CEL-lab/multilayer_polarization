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
#nodes that have democrat label
south_labels <- which(metadata['region']=='south')
#construct layers from tables from adjacency matrices
construct_layers_south <- function(type = "sup") {
  layers <- list()  # Create an empty list to store data frames and matrices
  for (i in 1:length(get(paste0(type, "_tables")))) {
    df <- dbReadTable(conn, get(paste0(type, "_tables"))[i])
    df <- df[, -1]  # Remove the first column
    df <- df %>%
      rename_with(~gsub("^X", "", .), starts_with("X")) %>% slice(which(metadata['region']=='south')) %>%  select(which(metadata['region']=='south')) %>% 
      as.matrix()
    # Assign the result to a list element
    layers[[paste0("layer", i)]] <- df
  }
  return(layers)
}
#construct supervised layers
layers_sup_south <- construct_layers_south("sup")
#layers_sup is a list of adjacency matrices
ilayers_sup_south <- lapply(layers_sup_south, function(adj_matrix) {
  graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
})
#construct unsupervised layers
layers_unsup_south <- construct_layers_south("unsup")
ilayers_unsup_south <- lapply(layers_unsup_south, function(adj_matrix) {
  graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
})
#create empty multiplex for supervised
multiplex_sup_south <- ml_empty()
#add igraph layers
for(i in 1:length(ilayers_sup_south)){
  if(length(E(ilayers_sup_south[[i]])!=0))
    add_igraph_layer_ml(multiplex_sup_south,ilayers_sup_south[[i]],sup_tables[i])
}

#create empty multiplex for unsupervised
multiplex_unsup_south <- ml_empty()
#add igraph layers
for(i in 1:length(ilayers_unsup_south)){
  if(length(E(ilayers_unsup_south[[i]])!=0))
    add_igraph_layer_ml(multiplex_unsup_south,ilayers_unsup_south[[i]],unsup_tables[i])
}
#plot
plot(multiplex_sup_south, vertex.labels = south_labels, vertex.labels.cex = 0.3, vertex.color = 'red', vertex.size = 0.05)
dev.off()
plot(multiplex_unsup, vertex.labels = south_labels, vertex.labels.cex = 0.3, vertex.color = 'red', vertex.size = 0.05)
dev.off()
#summary statistics for layers
summary(multiplex_sup_south)
summary(multiplex_unsup_south)

write.csv(summary(multiplex_sup_south), 'multiplex_sup_south.csv')
write.csv(summary(multiplex_unsup_south), 'multiplex_unsup_south.csv')
