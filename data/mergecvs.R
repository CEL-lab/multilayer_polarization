library(tidyverse)
#read separate csv files
original <- read.csv("/Users/harunpirim/Downloads/hashtags_406 - raw.csv")
unsup01 <- read.csv("/Users/harunpirim/Downloads/hashtags_406 - unsup_01.csv")
unsup03 <- read.csv("/Users/harunpirim/Downloads/hashtags_406 - unsup_03.csv")
unsup04 <- read.csv("/Users/harunpirim/Downloads/hashtags_406 - unsup_04.csv")
unsup05 <- read.csv("/Users/harunpirim/Downloads/hashtags_406 - unsup_05.csv")
unsup_01 <- read.csv("/Users/harunpirim/Downloads/hashtags_375 - unsup_01.csv")
unsup_02 <- read.csv("/Users/harunpirim/Downloads/hashtags_375 - unsup_02.csv")
unsup_03 <- read.csv("/Users/harunpirim/Downloads/hashtags_375 - unsup_03.csv")
unsup_04 <- read.csv("/Users/harunpirim/Downloads/hashtags_375 - unsup_04.csv")
unsup_05 <- read.csv("/Users/harunpirim/Downloads/hashtags_375 - unsup_05.csv")
# vector of read files
prompts <- c('unsup01', 'unsup03', 'unsup04', "unsup05", "unsup_01","unsup_02", "unsup_03", "unsup_04","unsup_05")
# merge all of files
for(i in 1:length(prompts)){
  original <- merge(original, get(prompts[i]), all.x = T)
}
original %>% select(-frequency,-unique_users,-Note,-unsup_05_note) -> sub_original

df <- sub_original %>% 
  mutate(total = rowSums(!is.na(across(starts_with("unsup")))))

write.csv(df, "all_prompts.csv")
