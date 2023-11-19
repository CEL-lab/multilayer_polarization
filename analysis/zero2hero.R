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
conn <- dbConnect(SQLite(), "/GitHub/multilayer_polarization/data/csvyerine2.db")

# read meta table
metadata <- dbReadTable(conn, "metadata")

# List all tables
tables <- dbListTables(conn)

# List supervised tables
sup_tables <- tables[tables %>% str_detect("^sup")]

# List unsupervised tables
unsup_tables <- tables[tables %>% str_detect("^unsup")]

# construct layers from tables from adjacency matrices
construct_layers <- function(type = "sup") {
  layers <- list() # Create an empty list to store data frames and matrices
  for (i in 1:length(get(paste0(type, "_tables")))) {
    df <- dbReadTable(conn, get(paste0(type, "_tables"))[i])
    df <- df[, -1] # Remove the first column
    df <- df %>%
      rename_with(~ gsub("^X", "", .), starts_with("X")) %>%
      as.matrix()
    # Assign the result to a list element
    layers[[paste0("layer", i)]] <- df
  }
  return(layers)
}

# construct supervised layers
layers_sup <- construct_layers("sup")
ilayers_sup <- lapply(layers_sup, function(adj_matrix) {
  graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
})

#add metadata to nodes

for(i in 1:length(ilayers_sup)){
  V(ilayers_sup[[i]])$region = metadata$region
  V(ilayers_sup[[i]])$party = metadata$finalParty
  V(ilayers_sup[[i]])$sex = metadata$finalSex
}

# construct unsupervised layers
layers_unsup <- construct_layers("unsup")
ilayers_unsup <- lapply(layers_unsup, function(adj_matrix) {
  graph_from_adjacency_matrix(adj_matrix, mode = "undirected")
})

# create empty multiplex for supervised
multiplex_sup <- ml_empty()
# add igraph layers
for (i in 1:length(ilayers_sup)) {
  add_igraph_layer_ml(multiplex_sup, ilayers_sup[[i]], sup_tables[i])
}

# calculate assortativity of graphs
assortativity_sup <- lapply(ilayers_sup, assortativity.degree)
names(assortativity_sup) <- sup_tables
dfa1 <- as.data.frame(assortativity_sup)
dfa1$model <- "Full"

# create empty multiplex for unsupervised
multiplex_unsup <- ml_empty()
# add igraph layers
for (i in 1:length(ilayers_unsup)) {
  add_igraph_layer_ml(multiplex_unsup, ilayers_unsup[[i]], unsup_tables[i])
}

# layer_econ1 <- graph_from_adjacency_matrix(layers_sup[[1]],"undirected")
# tkplot(layer_econ1)
# Read the table
# df_sup_econ <- dbReadTable(conn, "sup_econ")
# df_sup_econ <- df_sup_econ[,-1] #drop irrelecant column
# Remove 'x' from column names
# names(df_sup_econ) <- gsub("X", "", names(df_sup_econ))
# layer_econ <- graph_from_adjacency_matrix(as.matrix(df_sup_econ),"undirected")
# tkplot(layer_econ)
# assign colors to parties
color <- c()
for (i in 1:nrow((metadata))) {
  if (metadata[i, "finalParty"] == "Republican") {
    color <- append(color, 0)
  } else if (metadata[i, "finalParty"] == "Democrat") {
    color <- append(color, 1)
  } else {
    color <- append(color, 2)
  }
}
labels <- ifelse(color == "1", "Dem", ifelse(color == "0", "Rep", ifelse(color == "2", "Ind", color)))
colornew <- ifelse(color == "1", "blue", ifelse(color == "0", "red", ifelse(color == "2", "orange", color)))
# Get unique values from color
# unique_values <- unique(color)
# Generate unique color codes based on the number of unique values
# num_colors <- length(unique_values)
# color_palette <- brewer.pal(num_colors, "Set3")
# Create a color vector based on the unique values in C
# color_vector <- color_palette[match(color, unique_values)]
# plot
plot(multiplex_sup, vertex.labels = labels, vertex.labels.cex = 0.3, vertex.color = colornew, vertex.size = 0.05)
dev.off()
plot(multiplex_unsup, vertex.labels = labels, vertex.labels.cex = 0.3, vertex.color = colornew, vertex.size = 0.05)
dev.off()
# summary statistics for layers

summary(multiplex_sup)
summary(multiplex_unsup)

# community structure
clus <- glouvain_ml(multiplex_sup, omega = 1)

# Group by 'cid' and summarize the cluster sizes, ignoring layer repetitions
cluster_summary <- clus %>%
  distinct(actor, cid, .keep_all = TRUE) %>%
  group_by(cid) %>%
  summarize(cluster_size = n())

# Filter clusters with size 10 or more
clusters_with_10_or_more <- cluster_summary %>%
  filter(cluster_size >= 10)

# Print the clusters with size 10 or more
print(clusters_with_10_or_more)

clus10 <- clus %>% filter(cid %in% clusters_with_10_or_more$cid)
plot(multiplex_sup,  vertex.labels.cex = .5, vertex.labels = labels, com.cex = 0.0001, layout = )
#com = clus10,above
# Create an empty list to store actors in each cluster
actor_lists <- list()

# Iterate through clusters and store actors in the list
for (i in 1:nrow(clusters_with_10_or_more)) {
  cid_value <- clusters_with_10_or_more$cid[i]
  actors_in_cluster <- clus %>%
    filter(cid == cid_value) %>%
    pull(actor) %>%
    unique()

  actor_lists[[as.character(cid_value)]] <- actors_in_cluster
}

#pull cluster labels 
table(labels[as.numeric(actor_lists[[4]])])

# pull cluster labels
labels[as.numeric(actor_lists[[1]])]

# get_community_list_ml(clus,multiplex_sup)
# plot(multiplex_sup, com = clus)

write_ml(multiplex_sup, "multiplex_sup", format = "graphml")

# actor analysis

deg <- degree_ml(multiplex_sup)
top_degrees <- head(deg[order(-deg)],20)
top_actors <- head(unlist(actors_ml(multiplex_sup))[order(-deg)],20)
top_actors

# Initialize an empty list
list_02H <- list()

# Loop through the column names and add elements with values from f_x
for (col_name in sup_tables) {
  list_02H[[col_name]] <- degree_ml(multiplex_sup, actors = top_actors, layers = col_name)
}
list_02H[["flat"]] <- top_degrees

# Convert the list to a DataFrame
df_02H <- as.data.frame(list_02H)
row.names(df_02H) <- top_actors

# degree deviation among layers
sort(degree_deviation_ml(multiplex_sup, actors = top_actors))

# neighborhood and exclusive neighborhood
# exclusively present in these two layers, thus removing those layers
# will substantially impact the actor’s connectivity
neighborhood_ml(multiplex_sup, actors = top_actors, layers = sup_tables[1:2])
xneighborhood_ml(multiplex_sup, actors = top_actors, layers = sup_tables[1:2])

# compute relevance and xrelevance that is nighborhood in specific layers / overall neighborhood
# Initialize an empty list
r_list_02H <- list()
xr_list_02H <- list()

# Loop through the column names and add elements with values from f_x
for (col_name in sup_tables) {
  r_list_02H[[col_name]] <- relevance_ml(multiplex_sup, actors = top_actors, layers = col_name)
}

for (col_name in sup_tables) {
  xr_list_02H[[col_name]] <- xrelevance_ml(multiplex_sup, actors = top_actors, layers = col_name)
}

# Convert the list to a DataFrame
r_list_02H <- as.data.frame(r_list_02H)
row.names(r_list_02H) <- top_actors
xr_list_02H <- as.data.frame(xr_list_02H)
row.names(xr_list_02H) <- top_actors

# distance between actors
distance_ml(multiplex_sup, top_actors[1], top_actors[2])

#write tables into csv
write.csv(summary(multiplex_sup), 'multiplex_sup.csv')
write.csv(summary(multiplex_unsup), 'multiplex_unsup.csv')

