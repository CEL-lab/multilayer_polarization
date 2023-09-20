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
n <- nrow(subset(metadata,finalSex=='F'))
set.seed(123)  # Setting a seed for reproducibility
male_labels <- sample(which(metadata['finalSex'] == 'M'), n)
#nodes that have democrat label
#male_labels <- which(metadata['finalSex']=='M')

#construct layers from tables from adjacency matrices
construct_layers_male <- function(type = "sup") {
  layers <- list()  # Create an empty list to store data frames and matrices
  for (i in 1:length(get(paste0(type, "_tables")))) {
    df <- dbReadTable(conn, get(paste0(type, "_tables"))[i])
    df <- df[, -1]  # Remove the first column
    df <- df %>%
      rename_with(~gsub("^X", "", .), starts_with("X")) %>% slice(male_labels) %>%  select(male_labels) %>% 
      as.matrix()
    # Assign the result to a list element
    layers[[paste0("layer", i)]] <- df
  }
  return(layers)
}
#construct supervised layers
layers_sup_male <- construct_layers_male("sup")
#layers_sup is a list of adjacency matrices
ilayers_sup_male <- lapply(layers_sup_male, function(adj_matrix) {
  graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
})
#construct unsupervised layers
layers_unsup_male <- construct_layers_male("unsup")
ilayers_unsup_male <- lapply(layers_unsup_male, function(adj_matrix) {
  graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
})
#create empty multiplex for supervised
multiplex_sup_male <- ml_empty()
#add igraph layers
for(i in 1:length(ilayers_sup_male)){
  if(length(E(ilayers_sup_male[[i]])!=0))
    add_igraph_layer_ml(multiplex_sup_male,ilayers_sup_male[[i]],sup_tables[i])
}

#create empty multiplex for unsupervised
multiplex_unsup_male <- ml_empty()
#add igraph layers
for(i in 1:length(ilayers_unsup_male)){
  if(length(E(ilayers_unsup_male[[i]])!=0))
    add_igraph_layer_ml(multiplex_unsup_male,ilayers_unsup_male[[i]],unsup_tables[i])
}
#plot
plot(multiplex_sup_male, vertex.labels = male_labels, vertex.labels.cex = 0.3, vertex.color = 'red', vertex.size = 0.05)
dev.off()
plot(multiplex_unsup, vertex.labels = male_labels, vertex.labels.cex = 0.3, vertex.color = 'red', vertex.size = 0.05)
dev.off()
#summary statistics for layers
summary(multiplex_sup_male)
summary(multiplex_unsup_male)


write.csv(summary(multiplex_sup_male), 'multiplex_sup_male.csv')
write.csv(summary(multiplex_unsup_male), 'multiplex_unsup_male.csv')
