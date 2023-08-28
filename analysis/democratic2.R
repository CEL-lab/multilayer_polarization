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
democ_labels <- which(metadata['finalParty']=='Democrat')
#construct layers from tables from adjacency matrices
construct_layers_democ <- function(type = "sup") {
  layers <- list()  # Create an empty list to store data frames and matrices
  for (i in 1:length(get(paste0(type, "_tables")))) {
    df <- dbReadTable(conn, get(paste0(type, "_tables"))[i])
    df <- df[, -1]  # Remove the first column
    df <- df %>%
      rename_with(~gsub("^X", "", .), starts_with("X")) %>% slice(which(metadata['finalParty']=='Democrat')) %>%  select(which(metadata['finalParty']=='Democrat')) %>% 
      as.matrix()
    # Assign the result to a list element
    layers[[paste0("layer", i)]] <- df
  }
  return(layers)
}
#construct supervised layers
layers_sup_democ <- construct_layers_democ("sup")
#layers_sup is a list of adjacency matrices
ilayers_sup_democ <- lapply(layers_sup_democ, function(adj_matrix) {
  graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
})
#construct unsupervised layers
layers_unsup_democ <- construct_layers_democ("unsup")
ilayers_unsup_democ <- lapply(layers_unsup_democ, function(adj_matrix) {
  graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
})
#create empty multiplex for supervised
multiplex_sup_democ <- ml_empty()
#add igraph layers
for(i in 1:length(ilayers_sup_democ)){
  add_igraph_layer_ml(multiplex_sup_democ,ilayers_sup_democ[[i]],sup_tables[i])
}

#create empty multiplex for unsupervised
multiplex_unsup_democ <- ml_empty()
#add igraph layers
for(i in 1:length(ilayers_unsup_democ)){
  add_igraph_layer_ml(multiplex_unsup_democ,ilayers_unsup_democ[[i]],unsup_tables[i])
}
#plot
plot(multiplex_sup_democ, vertex.labels = democ_labels, vertex.labels.cex = 0.3, vertex.color = 'blue', vertex.size = 0.05)
dev.off()
plot(multiplex_unsup, vertex.labels = democ_labels, vertex.labels.cex = 0.3, vertex.color = 'blue', vertex.size = 0.05)
dev.off()
#summary statistics for layers
summary(multiplex_sup)
summary(multiplex_unsup)