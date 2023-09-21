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
repub_labels <- which(metadata['finalParty']=='Republican')
#construct layers from tables from adjacency matrices
construct_layers_repub <- function(type = "sup") {
  layers <- list()  # Create an empty list to store data frames and matrices
  for (i in 1:length(get(paste0(type, "_tables")))) {
    df <- dbReadTable(conn, get(paste0(type, "_tables"))[i])
    df <- df[, -1]  # Remove the first column
    df <- df %>%
      rename_with(~gsub("^X", "", .), starts_with("X")) %>% slice(which(metadata['finalParty']=='Republican')) %>%  select(which(metadata['finalParty']=='Republican')) %>% 
      as.matrix()
    # Assign the result to a list element
    layers[[paste0("layer", i)]] <- df
  }
  return(layers)
}
#construct supervised layers
layers_sup_repub <- construct_layers_repub("sup")
#layers_sup is a list of adjacency matrices
ilayers_sup_repub <- lapply(layers_sup_repub, function(adj_matrix) {
  graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
})
#construct unsupervised layers
layers_unsup_repub <- construct_layers_repub("unsup")
ilayers_unsup_repub <- lapply(layers_unsup_repub, function(adj_matrix) {
  graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
})
#create empty multiplex for supervised
multiplex_sup_repub <- ml_empty()
#add igraph layers
for(i in 1:length(ilayers_sup_repub)){
  if(length(E(ilayers_sup_repub[[i]])!=0))
  add_igraph_layer_ml(multiplex_sup_repub,ilayers_sup_repub[[i]],sup_tables[i])
}

assortativity_sup_repub <- lapply(ilayers_sup_repub, assortativity.degree)

#create empty multiplex for unsupervised
multiplex_unsup_repub <- ml_empty()
#add igraph layers
for(i in 1:length(ilayers_unsup_repub)){
  if(length(E(ilayers_unsup_repub[[i]])!=0))
  add_igraph_layer_ml(multiplex_unsup_repub,ilayers_unsup_repub[[i]],unsup_tables[i])
}
#plot
plot(multiplex_sup_repub, vertex.labels = repub_labels, vertex.labels.cex = 0.3, vertex.color = 'red', vertex.size = 0.05)
dev.off()
plot(multiplex_unsup, vertex.labels = repub_labels, vertex.labels.cex = 0.3, vertex.color = 'red', vertex.size = 0.05)
dev.off()
#summary statistics for layers
summary(multiplex_sup_repub)
summary(multiplex_unsup_repub)

jd_repub <- layer_comparison_ml(multiplex_sup_repub, method = 'jeffrey.degree')


jd_repub %>% as.matrix() %>% upper.tri() -> subset_repub
#as.matrix(df)[subset]

# Duplicate the dataframe
summary_similar <- jd_repub

# Check for numeric columns and update values
numeric_cols <- sapply(jd_repub, is.numeric)
summary_similar[, numeric_cols] <- lapply(jd_repub[, numeric_cols], function(col) {
  col < summary(as.matrix(jd_repub)[subset_repub])[2]
})

# Display the updated dataframe
print(summary_similar)

# Duplicate the dataframe
summary_dissimilar <- jd_repub

# Check for numeric columns and update values
numeric_cols <- sapply(jd_repub, is.numeric)
summary_dissimilar[, numeric_cols] <- lapply(jd_repub[, numeric_cols], function(col) {
  col > summary(as.matrix(jd_repub)[subset_repub])[5]
})

# Display the updated dataframe
print(summary_dissimilar)

pd_repub <- layer_comparison_ml(multiplex_sup_repub, method = 'pearson.degree')
je_repub <- layer_comparison_ml(multiplex_sup_repub, method = 'jaccard.edges')

pd_repub %>% as.matrix() %>% upper.tri() -> subset
#as.matrix(df)[subset]

# Duplicate the dataframe
summary_dissimilar <- pd_repub

# Check for numeric columns and update values
numeric_cols <- sapply(pd_repub, is.numeric)
summary_dissimilar[, numeric_cols] <- lapply(pd_repub[, numeric_cols], function(col) {
  col < summary(as.matrix(pd_repub)[subset_repub])[2]
})

# Display the updated dataframe
print(summary_dissimilar)

# Duplicate the dataframe
summary_similar <- pd_repub

# Check for numeric columns and update values
numeric_cols <- sapply(pd_repub, is.numeric)
summary_similar[, numeric_cols] <- lapply(pd_repub[, numeric_cols], function(col) {
  col > summary(as.matrix(pd_repub)[subset_repub])[5]
})

# Display the updated dataframe
print(summary_similar)



write.csv(summary(multiplex_sup_repub), 'multiplex_sup_repub.csv')
write.csv(summary(multiplex_unsup_repub), 'multiplex_unsup_repub.csv')

write.csv(pd_repub, 'pd_repub.csv')
write.csv(jd_repub, 'jd_repub.csv')

