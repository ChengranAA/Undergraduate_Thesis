library(tidyverse)
library(stringr)
library(reshape2)
library(RColorBrewer)

rm(list=ls())

main_dir = "/Users/lcraaaa/Documents/Files/term_2021/Thesis/Data_backup/Behaviour"
sub_list = list.dirs(main_dir, full.names = FALSE)[-1]
sub_list = as.list(sub_list)

# load a condition file for the experiment
condition_map <- read_csv("/Users/lcraaaa/Documents/Files/term_2021/Thesis/Experimemt_program/coder_hre/Resource/condition_map.csv") %>%
  select(-Trial)

# lead a correct answer file
HRT_ans <- read_csv("/Users/lcraaaa/Documents/Files/term_2021/Thesis/Experimemt_program/coder_hre/Resource/HRE_Experiment_Table.csv")

## Functions ##
# compare response string to the answer and return the corrected number
compare_resp <- function(resp, ans){
  correc <- 0
  for (i in 1:length(resp)) {
    if (toString(resp[i]) == toString(ans[i])) {
      correc = correc + 1
    }
  }
  return(correc)
}

# format response string to a list of strings
format_resp <- function(resp){
  resp <- toString(resp)
  resp <- as.list(strsplit(resp, ",")[[1]])
  for (i in 1:length(resp))
  {
    resp[i] <- str_extract(resp[i], "([:alpha:]{2})|\\?")
  }
  return(resp)
}

# format ans string to a list of strings
format_ans <- function(ans){
  ans <- toString(ans)
  ans <- as.list(strsplit(ans, ",")[[1]])
  return(ans)
}

# split sound sequence to string array
split_seq_sound <- function(chr_seq_sound) {
  str_seq_sound <- unlist(strsplit(chr_seq_sound, ","))
  str_seq_sound <- str_remove(str_seq_sound, ".wav")
  return(paste(str_seq_sound, sep = " ", collapse = ","))
}

split_seq_sound <- Vectorize(split_seq_sound)

## Data cleaning ##

# format answer
ans <- HRT_ans %>%
  unite(Filler_1, str_subset(colnames(HRT_ans), "Sound\\d{1}Filler"), sep = ",") %>%
  unite(Hebb_1, str_subset(colnames(HRT_ans), "Hebb\\d{1}$"), sep = ",") %>%
  unite(Filler_2, str_subset(colnames(HRT_ans), "Sound\\d{2}Filler"), sep = ",") %>%
  unite(Hebb_2, str_subset(colnames(HRT_ans), "Hebb\\d{2}$"), sep = ",")

clean_ans<- ans %>%
  select(starts_with(c("Hebb", "Filler"))) %>%
  lapply(split_seq_sound) %>%
  data.frame(row.names = 1:18) 

clean_ans_reorder <- clean_ans[ ,c("Filler_1", "Hebb_1", "Filler_2", "Hebb_2")]


# create a tibble for all the participants
all_sub_HRT_score <- tibble(
  Filler = numeric(),
  Hebb_non = numeric(),
  Hebb = numeric()
)

# calculate mean score for each participant
for (subject in sub_list) {
  # load the participant data
  HRT_file_prefix = paste("/Users/lcraaaa/Documents/Files/term_2021/Thesis/Data_backup/Behaviour/", subject, "/",sep = "")
  HRT_file_name <-paste(HRT_file_prefix, str_subset(list.files(HRT_file_prefix), "^(\\d){6}_(\\d){4}_(\\w){3}_(\\d){2}_(\\d){4}_HRT\\.csv$"), sep = "")
  SUB_HRT <- read_csv(HRT_file_name)
  
  # select the data
  SUB_HRT_resp <- SUB_HRT %>%
    select(contains("resp"))
  
  # remove NA
  SUB_HRT_resp <- SUB_HRT_resp[complete.cases(SUB_HRT_resp), ]
  
  # initialize a score tibble
  score <- tibble(
    score_1_filler = numeric(),
    score_1_hebb = numeric(),
    score_2_filler = numeric(), 
    score_2_hebb = numeric()
  )
  
  # calculate score for each response
  for (col_num in 1:4) {
    for (row_num in 1:18){
      score[row_num, col_num] = compare_resp(format_resp(SUB_HRT_resp[row_num, col_num]), format_ans(clean_ans_reorder[row_num, col_num]))
    }
  }
  
  # remove index number
  rm(col_num, row_num)
  
  # start a list for each condition
  filler_score <- list()
  hebb_non_score <- list()
  hebb_score <- list()
  
  # reorder the score by condition with the conditional mapping 
  for (col_num in 1:4) {
    for (row_num in 1:18){
      condition_type = as.numeric(condition_map[row_num, col_num])
      score_each = as.numeric(score[row_num, col_num])
      if (condition_type == 1) {
        filler_score = c(filler_score, score_each)
      } else if (condition_type == 2) {
        hebb_non_score = c(hebb_non_score, score_each)
      } else if (condition_type == 6) {
        hebb_score = c(hebb_score, score_each)
      }
    }
  }
  
  filler_mu = mean(unlist(filler_score))
  hebb_non_mu = mean(unlist(hebb_non_score))
  hebb_mu = mean(unlist(hebb_score))
  
  # add this participant to summerize tibble
  all_sub_HRT_score <- all_sub_HRT_score %>%
    add_row(Filler = filler_mu, 
            Hebb_non = hebb_non_mu, 
            Hebb = hebb_mu)
}



## Data analysis and Visualization ##

all_sub_HRT_summarize <- all_sub_HRT_score %>%
  summarise(mu_filler = mean(Filler), sd_filler=sd(Filler), 
            mu_hebb_non = mean(Hebb_non), sd_hebb_non = sd(Hebb_non), 
            mu_hebb = mean(Hebb), sd_hebb = sd(Hebb))

all_sub_HRT_long <- melt(all_sub_HRT_score) %>%
  group_by(variable) %>%
  summarise(mu = mean(value), sd = sd(value))

ggplot(all_sub_HRT_long, aes(x = variable, y = mu, fill = variable)) +
  geom_bar(stat = "identity") +
  geom_errorbar(aes(ymin=mu-sd, ymax=mu+sd, width=.2))+
  theme_classic() +
  scale_y_continuous(limits = c(0,8), expand = c(0, 0)) +
  xlab("Conditions") +
  ylab("Mean memory test score") +
  scale_fill_brewer(palette="Blues", name = "Conditions")
         










