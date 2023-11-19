# Master's thesis Psychology
# University of Zurich
# Author: Berit Barthelmes

import xml.etree.ElementTree as ET
import os
from tqdm import tqdm

# assign directory
# adapt directories to your needs
articles_directory = "../articles_xml/" # unfiltered


def filter_duplicate_articles(directory):
  i = 0
  files = os.listdir(directory)
  seen = set()
  duplicate_files = []

  # iterate over files in that directory
  for filename in tqdm(files):
    if filename.endswith(".xml"):
      # print(directory, filename)
      file = os.path.join(directory, filename)
      # checking if it is a file
      tree = ET.parse(file)
      root = tree.getroot()
      article_hash = root.find(".//{http://www.tei-c.org/ns/1.0}idno[@type='MD5']").text
      i += 1
      if article_hash not in seen:
        seen.add(article_hash)
      else:
        duplicate_files.append(filename)

  print("Total files: ", i)
  print("Duplicate files: ", len(duplicate_files))
  return duplicate_files

def remove_duplicate_articles(duplicates):
  for duplicate in duplicates:
    os.remove(os.path.join(articles_directory, duplicate))

duplicates = filter_duplicate_articles(articles_directory)
remove_duplicate_articles(duplicates)

