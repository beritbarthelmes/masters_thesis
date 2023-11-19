# Master's thesis Psychology
# University of Zurich
# Author: Berit Barthelmes

###################################
#            CROSSREF             #
#            ARTICLES             #
###################################

##### Packages ####
# Required by fulltext package
remotes::install_github("ropensci-archive/microdemic")
remotes::install_github("ropensci/fulltext")
install.packages("xml2")
install.packages("httr")
install.packages("broom")
install.packages("data.table")
install.packages("jsonlite")

library(rentrez)
library(fulltext)
library(xml2)
library(httr)
library(dplyr)
library(tidyr)
library(broom)
library(data.table)
library(jsonlite)

##### Retrieve metadata from Crossref ####

# Get request for Crossref using deep paging (no limits on size of query), get all DOIs and ISSN's for all available papers in PDF and XML format for search query "memory decay"
articles <- list()
# GET first 1000 article metadata, set cursor with first query
response <- GET("https://api.crossref.org/works?query='memory%20decay'&select=DOI,ISSN&cursor=*&rows=1000&filter=full-text.type:application/xml,full-text.type:application/pdf,", timeout(20)) # GET function from httr package: get a url, timeout to avoid that operation times out

# Getting "response" in string format
# Parse response from string to named list
response <- content(response, "parsed") 
articles <- append(articles, response$message$items) 

# Repeat loop for fetching article metadata and binding it in object "articles"
i <- 0

repeat {
  query_string <- paste0("https://api.crossref.org/works?query='memory%20decay'&select=DOI,ISSN&rows=1000&filter=full-text.type:application/xml,full-text.type:application/pdf&cursor=", response$message["next-cursor"]) # paste0(): concatenate vectors after converting to character vectors, usage of cursors because we would otherwise run into timeouts during the request, API has a limit, search queries include 1000 articles
  print(query_string)
  response <- GET(query_string, timeout(20)) 
  # Parse response from string to named list
  response <- content(response, "parsed")
  if (length(response$message$items) == 0) 
      break
  articles <- append(articles, response$message$items)
  print(i)
  print(length(response$message$items))
  i <- i+1
}

##### Create publisher distribution table ####

# Create key value pairs for publisher distribution
publishers <- list()
publishers[["NA"]] <- 0
subject_count <- 0

# Loop for filling publishers list
for (article in articles) {
  if (is.null(article$publisher)) {
    publishers[["NA"]] <- publishers[["NA"]] + 1 
    next
  }
  if (is.null(publishers[[article$publisher]])) {
    publishers[[article$publisher]] <- 1
  } else {
    publishers[[article$publisher]] <- publishers[[article$publisher]] + 1
  }
}

# Sort list in ascending order
publisher_distribution <- publishers[order(-unlist(publishers))]

# Create data frame for csv table
publisher_distribution <- data.frame(publishers=names(publisher_distribution),
                                     count=unname(unlist(publisher_distribution))) 

write.csv(publisher_distribution, "Publisher_distribution.csv", row.names = F)


##### Create journal distribution table ####

# Create key value pairs for journal-title distribution -> same procedure as for the publishers, only the ISSN's must be translated into journal names additionally
issn_list <- list()
issn_list[["NA"]] <- 0
journal_count <- 0

# Fill list with ISSN's from articles
for (article in articles) {
  issn <- article$ISSN[[1]][1]
  if (is.null(issn)) {
    print(article$ISSN)
    issn_list[["NA"]] <- issn_list[["NA"]] + 1 
    next
  }
  if (is.null(issn_list[[issn]])) {
    issn_list[[issn]] <- 1 
  } else {
    issn_list[[issn]] <- issn_list[[issn]] + 1 
  }
}

# Create key value pairs
journal_list <- list()
journal_list[["NA"]] <- issn_list[[1]]

# Set counter to two since first position is NA
i <- 2

# Fill list with journal names and count of articles
for (issn in names(issn_list)[2:length(issn_list)]) { 
  print(issn)
  query_string <- paste0("https://api.crossref.org/journals/", issn) 
  response <- GET(query_string) 
  if (response$status_code == 404) { 
    print("Journal not found")
    journal_list[["NA"]] <- journal_list[["NA"]] + 1 
    next
  }
  response <- content(response) 
  journal_name = response$message$title 
  journal_list[[journal_name]] <- issn_list[[i]] 
  i <- i + 1
}

# Sort list in ascending order
journals_distribution <- journal_list[order(-unlist(journal_list))]

# Create data frame for csv table
journals_distribution <- data.frame(Journal=names(journals_distribution),
                                    Count=unname(unlist(journals_distribution))) 

write.csv(journals_distribution, "Journals_distribution.csv", row.names = F)

issn_list_sorted <- issn_list[order(-unlist(issn_list))]

relevant_issn <- c("0090-502x", "1750-6980", "0028-0836", "1069-9384", 
                   "0006-4971", "1747-0218", "0956-7976", "0340-0727", 
                   "1943-3921", "0033-3131")
relevant_articles <- Filter(function(x) !is.null(x$ISSN) && x$ISSN[1] %in% relevant_issn, articles)
relevant_dois <- Map(function(x) if (!is.null(x$DOI)) x$DOI, relevant_articles)
write.table(relevant_dois, "crossref_relevant_dois.csv", sep=",",  col.names=FALSE)
