# Create a function to check if two Twit IDs share the same hashtag
share_same_hashtag <- function(id1, id2, data) {
  hashtags1 <- data$hashtag[data$twitter_id == id1]
  hashtags2 <- data$hashtag[data$twitter_id == id2]
  
  if (any(hashtags1 %in% hashtags2)) {
    return(1)
  } else {
    return(0)
  }
}

# Iterate through the matrix and fill it with 1 or 0 depending on whether the Twit IDs share the same hashtag or not


for (i in seq_len(nrow(lg_mat))) {
  for (j in seq_len(ncol(lg_mat))) {
    id1 <- rownames(lg_mat)[i]
    id2 <- colnames(lg_mat)[j]
    
    if (id1 != id2) {
      lg_mat[i, j] <- share_same_hashtag(id1, id2, lg)
    } else {
      lg_mat[i, j] <- 0
    }
  }
}

# Display the updated matrix
lg_mat


layer1 <-graph_from_adjacency_matrix(lg_mat,"undirected")
