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
fem_labels <- which(metadata['finalSex']=='F')
#construct layers from tables from adjacency matrices
construct_layers_fem <- function(type = "sup") {
  layers <- list()  # Create an empty list to store data frames and matrices
  for (i in 1:length(get(paste0(type, "_tables")))) {
    df <- dbReadTable(conn, get(paste0(type, "_tables"))[i])
    df <- df[, -1]  # Remove the first column
    df <- df %>%
      rename_with(~gsub("^X", "", .), starts_with("X")) %>% slice(which(metadata['finalSex']=='F')) %>%  select(which(metadata['finalSex']=='F')) %>% 
      as.matrix()
    # Assign the result to a list element
    layers[[paste0("layer", i)]] <- df
  }
  return(layers)
}
#construct supervised layers
layers_sup_fem <- construct_layers_fem("sup")
#layers_sup is a list of adjacency matrices
ilayers_sup_fem <- lapply(layers_sup_fem, function(adj_matrix) {
  graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
})
#construct unsupervised layers
layers_unsup_fem <- construct_layers_fem("unsup")
ilayers_unsup_fem <- lapply(layers_unsup_fem, function(adj_matrix) {
  graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
})
#create empty multiplex for supervised
multiplex_sup_fem <- ml_empty()
#add igraph layers
for(i in 1:length(ilayers_sup_fem)){
  if(length(E(ilayers_sup_fem[[i]])!=0))
    add_igraph_layer_ml(multiplex_sup_fem,ilayers_sup_fem[[i]],sup_tables[i])
}

#create empty multiplex for unsupervised
multiplex_unsup_fem <- ml_empty()
#add igraph layers
for(i in 1:length(ilayers_unsup_fem)){
  if(length(E(ilayers_unsup_fem[[i]])!=0))
    add_igraph_layer_ml(multiplex_unsup_fem,ilayers_unsup_fem[[i]],unsup_tables[i])
}
#plot
plot(multiplex_sup_fem, vertex.labels = fem_labels, vertex.labels.cex = 0.3, vertex.color = 'red', vertex.size = 0.05)
dev.off()
plot(multiplex_unsup, vertex.labels = fem_labels, vertex.labels.cex = 0.3, vertex.color = 'red', vertex.size = 0.05)
dev.off()
#summary statistics for layers
summary(multiplex_sup_fem)
summary(multiplex_unsup_fem)

write.csv(summary(multiplex_sup_fem), 'multiplex_sup_fem.csv')
write.csv(summary(multiplex_unsup_fem), 'multiplex_unsup_fem.csv')

