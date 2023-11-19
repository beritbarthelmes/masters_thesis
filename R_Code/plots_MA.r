# Master's thesis Psychology
# University of Zurich
# Author: Berit Barthelmes

library("readxl")
library("ggplot2")
library(ggpubr)
theme_set(theme_pubr())
library("plotly")
library("psych")
library("dplyr2")
library("lubridate")
library("plotKML")
library("ggmap")
library("magrittr")
library("gghighlight")
library("tidyr")

# Load csv
dat <- read.csv("MA_Data_Knowledge_Accumulation.csv")
dat <- as.data.frame(dat)

# Amount of articles, n=472
nrow(dat) 

# Article types (0-2)
table_article_types <- table(dat$article.type)
names(table_article_types) <- c("Review", "Empirical", "Modeling/theoretical")
ylim = c(0, 500)  ## set plotting range
plot_article_types <- barplot(table_article_types, space = 0, col = 8, main = "Amount of reviews, empirical or \n modeling/theoretical articles", ylim = ylim)

legend("topright", legend = c("Review, n=3","Empirical, n=453","Modeling/Theoretical, n=16" ), 
       col = 10, cex = 0.8, horiz = FALSE)

# Basic or applied research (0/1)
table_basic_or_applied <- table(dat$basic.or.applied.research.)
names(table_basic_or_applied) <- c("Basic", "Applied")
ylim = c(0, 500)  ## set plotting range
plot_basic_or_applied <- barplot(table_basic_or_applied, space = 0, col = 8, main = "Amount of basic or applied research", ylim = ylim)

legend("topright", legend = c("Basic, n=396","Applied, n=76"), 
       col = 10, cex = 0.8, horiz = FALSE)

# Expert categorization of articles (0-3)
table_article_categorization <- table(dat$expert1_categorization)
names(table_article_categorization) <- c("Ambiguous", "Against", "Support", "Tacit acceptance")
ylim = c(0, 300)  ## set plotting range
plot_article_categorization <- barplot(table_article_categorization, space = 0, col = 8, main = "Expert categorization of articles", ylim = ylim)

legend("topleft", legend = c("Ambiguous, n=30","Against, n=84","Support, n=269","Tacit acceptance, n=89"), 
       col = 10, cex = 0.8, horiz = FALSE)

# GPT-4 categorization of abstracts, mean rating of 10x abstract ratings (0-3, NA)
table_gpt4_abstract_mean_rating <- table(dat$abstract_rating_category_mean)
names(table_gpt4_abstract_mean_rating) <- c("Ambiguous", "Against", "Support", "Tacit acceptance")
ylim = c(0, 300)  ## set plotting range
plot_gpt4_abstract_mean_rating <- barplot(table_gpt4_abstract_mean_rating, space = 0, col = 8, main = "GPT-4 categorization of abstracts", ylim = ylim)

legend("topleft", legend = c("Ambiguous, n=25","Against, n=78","Support, n=279","Tacit acceptance, n=87", "NA, n=3"), 
       col = 10, cex = 0.8, horiz = FALSE)

# GPT-4 categorization of paragraphs, mean rating 3 paragraphs (0-3, NA)
# p1
table_gpt4_p1_mean_rating  <- table(dat$p1_rating_category)
names(table_gpt4_p1_mean_rating) <- c("Ambiguous", "Against", "Support", "Tacit acceptance")
ylim = c(0, 300)  ## set plotting range
plot_gpt4_p1_mean_rating <- barplot(table_gpt4_p1_mean_rating, space = 0, col = 8, main = "GPT-4 categorization of paragraphs: paragraph 1", ylim = ylim)

legend("topleft", legend = c("Ambiguous, n=101","Against, n=39","Support, n=220","Tacit acceptance, n=63", "NA, n=49"), 
       col = 10, cex = 0.8, horiz = FALSE)

# p2
table_gpt4_p2_mean_rating  <- table(dat$p2_rating_category)
names(table_gpt4_p2_mean_rating) <- c("Ambiguous", "Against", "Support", "Tacit acceptance")
ylim = c(0, 300)  ## set plotting range
plot_gpt4_p2_mean_rating <- barplot(table_gpt4_p2_mean_rating, space = 0, col = 8, main = "GPT-4 categorization of paragraphs: paragraph 2", ylim = ylim)

legend("topleft", legend = c("Ambiguous, n=79","Against, n=42","Support, n=205","Tacit acceptance, n=82", "NA, n=64"), 
       col = 10, cex = 0.8, horiz = FALSE)

# p3
table_gpt4_p3_mean_rating  <- table(dat$p3_rating_category)
names(table_gpt4_p3_mean_rating) <- c("Ambiguous", "Against", "Support", "Tacit acceptance")
ylim = c(0, 300)  ## set plotting range
plot_gpt4_p3_mean_rating <- barplot(table_gpt4_p3_mean_rating, space = 0, col = 8, main = "GPT-4 categorization of paragraphs: paragraph 3", ylim = ylim)

legend("topleft", legend = c("Ambiguous, n=94","Against, n=50","Support, n=169","Tacit acceptance, n=77", "NA, n=82"), 
       col = 10, cex = 0.8, horiz = FALSE)

# Mean p1-p3
table_gpt4_p_mean_rating  <- table(dat$p_mean_rating)
names(table_gpt4_p_mean_rating) <- c("Ambiguous", "Against", "Support", "Tacit acceptance")
ylim = c(0, 300)  ## set plotting range
plot_gpt4_p_mean_rating <- barplot(table_gpt4_p_mean_rating, space = 0, col = 8, main = "GPT-4 categorization of paragraphs: paragraphs 1-3 mean", ylim = ylim)

legend("topleft", legend = c("Ambiguous, n=8","Against, n=112","Support, n=173","Tacit acceptance, n=18", "NA, n=179"), 
       col = 10, cex = 0.8, horiz = FALSE)

# Does the article explicitly argue for an interplay between decay and interference/ includes both in a model of memory loss?
table_interplay_decay_interference <- table(dat$Does.the.article.explicitly.argue.for.an.influence.of.both.decay.and.interference.on.memory.loss.)
names(table_interplay_decay_interference) <- c("No", "Yes")
ylim = c(0, 500)  ## set plotting range
plot_interplay_decay_interference <- barplot(table_interplay_decay_interference, space = 0, col = 8, main = "Does the article explicitly argue \n for a combination of decay and interference?", ylim = ylim)

legend("topright", legend = c("No, n=454","Yes, n=18"), 
       col = 10, cex = 0.8, horiz = FALSE)

# Does the article explicitly propose a new principle or theory to explain memory loss?
table_new_principle <- table(dat$Does.the.article.explicitly.propose.a.new.principle.or.theory.to.explain.memory.loss.)
names(table_new_principle) <- c("No", "Yes")
ylim = c(0, 500)  ## set plotting range
plot_new_principle <- barplot(table_new_principle, space = 0, col = 8, main = "Does the article explicitly propose a different principle \n than the memory decay theory to explain memory loss?", ylim = ylim)

legend("topright", legend = c("No, n=455","Yes, n=17"), 
       col = 10, cex = 0.8, horiz = FALSE)

# Overview on publishing dates of articles
min(dat$date)
max(dat$date)

# Cosine similarity scores
min(dat$p1_cos_similarity)
max(dat$p1_cos_similarity)

min(dat$p2_cos_similarity)
max(dat$p2_cos_similarity)

min(dat$p3_cos_similarity)
max(dat$p3_cos_similarity)

# Comparison GPT-4 abstract, paragraphs and expert rating, interrater reliability 
# Expert & GPT-4 paragraph categorizations

# Expert & paragraph 1
cohen.kappa(x=cbind(dat$expert1_categorization, dat$p1_rating_category))

# Expert & paragraph 2
cohen.kappa(x=cbind(dat$expert1_categorization, dat$p2_rating_category))

# Expert & paragraph 3
cohen.kappa(x=cbind(dat$expert1_categorization, dat$p3_rating_category))

# Expert & paragraph mean rating
cohen.kappa(x=cbind(dat$expert1_categorization, dat$p_mean_rating))

# Expert & GPT-4 abstract categorizations
cohen.kappa(x=cbind(dat$expert1_categorization, dat$abstract_rating_category_mean))

# GPT-4 abstract & paragraph categorizations
cohen.kappa(x=cbind(dat$abstract_rating_category_mean, dat$p_mean_rating))

# Timeline, expert categorization of articles by years
dat_excel <- read_excel("MA_Data_Knowledge_Accumulation.xlsx")

# Tranform date
date_as_date <- as.Date(as.POSIXct(dat_excel$date, "CST"))
date_year <- format(date_as_date, "%Y")

# Create data frames for each year with categorizations
cat0_by_year <- dat_excel %>% 
                  group_by(year = lubridate::floor_date(date, "year")) %>%
                  summarize(summary_variable = sum(expert1_categorization == 0))

cat1_by_year <- dat_excel %>% 
                  group_by(year = lubridate::floor_date(date, "year")) %>%
                  summarize(summary_variable = sum(expert1_categorization == 1))

cat2_by_year <- dat_excel %>% 
                  group_by(year = lubridate::floor_date(date, "year")) %>%
                  summarize(summary_variable = sum(expert1_categorization == 2))

cat3_by_year <- dat_excel %>% 
                  group_by(year = lubridate::floor_date(date, "year")) %>%
                  summarize(summary_variable = sum(expert1_categorization == 3))

# Plot timeline
plot_timeline_articles <- data.frame(Year = cat0_by_year$year, 
                          Amount = c(cat0_by_year$summary_variable,
                                    cat1_by_year$summary_variable,
                                    cat2_by_year$summary_variable,
                                    cat3_by_year$summary_variable),
                          Type = c(rep("Ambiguous", length(cat0_by_year$year)), 
                                   rep("Against", length(cat0_by_year$year)), 
                                   rep("Support", length(cat0_by_year$year)), 
                                   rep("Tacit acceptance", length(cat0_by_year$year))))

ggplot(plot_timeline_articles) + 
  geom_line(aes(Year, Amount, colour = Type)) 

ggplot(plot_timeline_articles) + 
  geom_line(aes(Year, Amount, colour = Type)) +
  gghighlight(Type == "Ambiguous") +
  scale_color_manual(values=c('Green'))

ggplot(plot_timeline_articles) + 
  geom_line(aes(Year, Amount, colour = Type)) +
  gghighlight(Type == "Against") +
  scale_color_manual(values=c('Red'))

ggplot(plot_timeline_articles) + 
  geom_line(aes(Year, Amount, colour = Type)) +
  gghighlight(Type == "Support") +
  scale_color_manual(values=c('Blue'))

ggplot(plot_timeline_articles) + 
  geom_line(aes(Year, Amount, colour = Type)) +
  gghighlight(Type == "Tacit acceptance") +
  scale_color_manual(values=c('purple'))

# Divide GPS data into lat, lon
dat_excelgps_coordinates <- dat_excel %>%
                    filter(`first author university coordinates (Latitude, Longitude)` != '0,0') %>%
                    separate(`first author university coordinates (Latitude, Longitude)`, into = c('lat', 'lon'), sep=",")


