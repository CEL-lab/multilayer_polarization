#zero2hero data usage
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
#construct layers from tables from adjacency matrices
construct_layers <- function(type = "sup") {
  layers <- list()  # Create an empty list to store data frames and matrices
  for (i in 1:length(get(paste0(type, "_tables")))) {
    df <- dbReadTable(conn, get(paste0(type, "_tables"))[i])
    df <- df[, -1]  # Remove the first column
    df <- df %>%
      rename_with(~gsub("^X", "", .), starts_with("X")) %>%
      as.matrix()
    # Assign the result to a list element
    layers[[paste0("layer", i)]] <- df
  }
  return(layers)
}
#construct supervised layers
layers_sup <- construct_layers("sup")
#layers_sup is a list of adjacency matrices
ilayers_sup <- lapply(layers_sup, function(adj_matrix) {
  graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
})
#construct unsupervised layers
layers_unsup <- construct_layers("unsup")
ilayers_unsup <- lapply(layers_unsup, function(adj_matrix) {
  graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
})
#create empty multiplex for supervised
multiplex_sup <- ml_empty()
#add igraph layers
for(i in 1:length(ilayers_sup)){
  add_igraph_layer_ml(multiplex_sup,ilayers_sup[[i]],sup_tables[i])
}

#calculate assortativity of graphs
assortativity_sup <- lapply(ilayers_sup, assortativity.degree)
head(sort(degree_ml(multiplex_sup),decreasing = T))

#create empty multiplex for unsupervised
multiplex_unsup <- ml_empty()
#add igraph layers
for(i in 1:length(ilayers_unsup)){
  add_igraph_layer_ml(multiplex_unsup,ilayers_unsup[[i]],unsup_tables[i])
}

#layer_econ1 <- graph_from_adjacency_matrix(layers_sup[[1]],"undirected")
#tkplot(layer_econ1)
# Read the table
#df_sup_econ <- dbReadTable(conn, "sup_econ")
#df_sup_econ <- df_sup_econ[,-1] #drop irrelecant column
# Remove 'x' from column names
#names(df_sup_econ) <- gsub("X", "", names(df_sup_econ))
#layer_econ <- graph_from_adjacency_matrix(as.matrix(df_sup_econ),"undirected")
#tkplot(layer_econ)
#assign colors to parties
color <- c()
for (i in 1:nrow((metadata))) {
  if (metadata[i, "finalParty"] == "Republican") {
    color <- append(color, 0)
  } else if (metadata[i, "finalParty"] == "Democrat") {
    color <- append(color, 1)
  }
    else {
    color <- append(color, 2) 
    }
}
labels <- ifelse(color == "1", "Dem", ifelse(color == "0", "Rep", ifelse(color == "2", "Ind", color)))
colornew <- ifelse(color == "1", "blue", ifelse(color == "0", "red", ifelse(color == "2", "orange", color)))
# Get unique values from color
#unique_values <- unique(color)
# Generate unique color codes based on the number of unique values
#num_colors <- length(unique_values)
#color_palette <- brewer.pal(num_colors, "Set3")
# Create a color vector based on the unique values in C
#color_vector <- color_palette[match(color, unique_values)]
# plot
plot(multiplex_sup, vertex.labels = labels, vertex.labels.cex = 0.3, vertex.color = colornew, vertex.size = 0.05)
dev.off()
plot(multiplex_unsup, vertex.labels = labels, vertex.labels.cex = 0.3, vertex.color = colornew, vertex.size = 0.05)
dev.off()
#summary statistics for layers
summary(multiplex_sup)
summary(multiplex_unsup)

write.csv(summary(multiplex_sup), 'multiplex_sup.csv')
write.csv(summary(multiplex_unsup), 'multiplex_unsup.csv')
