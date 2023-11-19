# Master's thesis Psychology
# University of Zurich
# Author: Berit Barthelmes

# Install packages
install.packages("rentrez")
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

# Show 2000 entries
options(max.print=2000)

# Functions that help to learn about NCBI databases
# entrez_db_summary("pubmed")	
# entrez_db_searchable("pubmed")
# entrez_db_links("pubmed")

# Available NCBI databases
#####
##  [1] "pubmed"          "protein"         "nuccore"         "ipg"            
##  [5] "nucleotide"      "structure"       "sparcle"         "protfam"        
##  [9] "genome"          "annotinfo"       "assembly"        "bioproject"     
## [13] "biosample"       "blastdbinfo"     "books"           "cdd"            
## [17] "clinvar"         "gap"             "gapplus"         "grasp"          
## [21] "dbvar"           "gene"            "gds"             "geoprofiles"    
## [25] "homologene"      "medgen"          "mesh"            "ncbisearch"     
## [29] "nlmcatalog"      "omim"            "orgtrack"        "pmc"            
## [33] "popset"          "proteinclusters" "pcassay"         "biosystems"     
## [37] "pccompound"      "pcsubstance"     "seqannot"        "snp"            
## [41] "sra"             "taxonomy"        "biocollections"  "gtr"

###################################
#             PUBMED              #
#            ARTICLES             #
###################################

# Searching database, getting DOIs from articles
# "memory decay" = 189 hits
# retmax = How many articles will be fetched
r_search_pubmed <- entrez_search(db="pubmed", term='"memory decay"', retmax=200)

# Create vector with PubMed IDs
r_search_pubmed_ids <- c(r_search_pubmed$ids)

# Retrieve full information about articles/ metadata
pubmed_articles <- entrez_summary(db = "pubmed", id=r_search_pubmed_ids)

# Extract DOIs from metadata 
doi_pubmed <- list()
for (article in pubmed_articles) {
  doi_attribute_index <- match("doi", article$articleids$idtype)
  # print(doi_attribute_index)
  if (is.na(doi_attribute_index)) {
    next 
  }
  doi_pubmed <- append(doi_pubmed, article$articleids$value[[doi_attribute_index]])
}

# Get full text PDFs from DOIs
# Article 114 didn't download, 54 articles/ 178 were downloadable
cache_options_set(full_path = "pubmed_articles")
res <- ft_get(unlist(doi_pubmed[-114]), type = "xml")


###################################
#              PMC                #
#            ARTICLES             #
###################################

# Searching database, getting DOIs from articles
# (limiting search query to max 200 entries per request because of rate limit of server)
# "memory decay" = 1240 hits
r_search_pmc_ids <- list()
for (i in seq(0, 1240, 200)) {
  # "memory decay" = 1240 hits
  search <- entrez_search(db="pmc", term='"memory decay"', retstart=i, retmax=200)
  r_search_pmc_ids <- append(r_search_pmc_ids, search$ids)
}

# Create ID vector
r_search_pmc_ids <- unlist(r_search_pmc_ids)

# Retrieve full information about articles (considering rate limit like above)
pmc_articles <- list()
for (i in seq(1, 1240, 200)) {
  articles <- entrez_summary(db = "pmc", id=r_search_pmc_ids[i:(i+199)])
  pmc_articles <- append(pmc_articles, articles)
}

# Fetch DOIs (remove NAs)
doi_pmc <- list()
for (article in pmc_articles) {
  doi_attribute_index <- match("doi", article$articleids$idtype)
  if (is.na(doi_attribute_index)) {
    next 
  }
  doi_pmc <- append(doi_pmc, article$articleids$value[[doi_attribute_index]])
}

# Get fulltext PDF
# 447 articles/ 1222 were downloadable
# files that could not be downloaded: 190, 504, 518, 842, 866, 1044
doi_pmc <- unlist(doi_pmc)
cache_options_set(full_path = "pmc_articles")
res <- ft_get(doi_pmc[-c(190,504,518,842,866,1044)], type = "xml")


###################################
#              PLOS               #
#            ARTICLES             #
###################################

# in the unit tests of the ft_get function on github, 
# the function call using "plos" as the from parameter 
# is commented and only shows an error for every plos doi when tested
# https://github.com/ropensci-archive/fulltext/blob/master/tests/testthat/test-ft_get.r (line 26)
# but ft_search works to fetch the DOIs

plos_articles <- ft_search(query = '"memory decay"', from = 'plos', limit=200)
# res <- ft_get(plos_articles$plos$data$id)
doi_plos <- plos_articles$plos$data$id

dir.create(file.path(".", "plos_articles"), showWarnings = FALSE)
for (doi in doi_plos) {
  url <- paste("https://journals.plos.org/plosone/article/file?id=", doi, "&type=manuscript", sep = "")
  filename <- gsub("[.\\/]+", "_", doi)
  xml_file <- download_xml(url, file=paste("./plos_articles/", filename, ".xml", sep = ""))
}


###################################
#              PLOS               #
#            ARTICLES             #
#            PARSING              #
###################################

# Get fulltext as plaintext, from XML to plaintext
files <- list.files(path="./plos_articles", pattern="*.xml", full.names=TRUE, recursive=FALSE)

for (file in files) {
  read_xml()
}

###################################
#            CROSSREF             #
#            ARTICLES             #
###################################

# Get request for Crossref using deep paging (no limits on size of query), get all DOIs and publishers
articles <- list()
# response <- GET("https://api.crossref.org/works?query='memory%20decay'&select=publisher,DOI,subject,container-title&cursor=*&rows=1000&filter=full-text.type:application/xml,full-text.type:application/pdf", timeout(20))
# for PDF articles
response <- GET("https://api.crossref.org/works?query='memory%20decay'&select=DOI,ISSN&cursor=*&rows=1000&filter=full-text.type:application/xml,full-text.type:application/pdf,", timeout(20))
# Parse response from string to named list
response <- content(response, "parsed")
articles <- append(articles, response$message$items)

i <- 0

# for PDF articles 

repeat {
  query_string <- paste0("https://api.crossref.org/works?query='memory%20decay'&select=DOI,ISSN&rows=1000&filter=full-text.type:application/xml,full-text.type:application/pdf&cursor=", response$message["next-cursor"])
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

# Only 507 of 24251 found articles have a subject field

# Create key value pairs for publisher distribution
publishers <- list()
publishers[["NA"]] <- 0
subject_count <- 0
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

publisher_distribution <- data.frame(publishers=names(publisher_distribution),
                                     count=unname(unlist(publisher_distribution)))

write.csv(publisher_distribution, "Publisher_distribution.csv", row.names = F)

# Create key value pairs for journal-title distribution
issn_list <- list()
issn_list[["NA"]] <- 0
journal_count <- 0
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

response <- GET("https://api.crossref.org/journals/0001-8243")

journal_list <- list()
journal_list[["NA"]] <- issn_list[[1]]
i <- 2
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

journals_distribution <- data.frame(Journal=names(journals_distribution),
                                     Count=unname(unlist(journals_distribution)))

write.csv(journals_distribution, "Journals_distribution.csv", row.names = F)