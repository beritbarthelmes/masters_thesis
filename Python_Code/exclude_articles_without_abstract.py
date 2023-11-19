# Master's thesis Psychology
# University of Zurich
# Author: Berit Barthelmes

import xml.etree.ElementTree as ET
import os

# assign directory
articles_directory = "../articles_xml/"

no_abstract_files = []
files = os.listdir(articles_directory)

# iterate over files in that directory
for filename in files:
  if filename.endswith(".xml"):
    # print(directory, filename)
    file = os.path.join(articles_directory, filename)
    # checking if it is a file
    tree = ET.parse(file)
    root = tree.getroot()
    abstract = root.find(".//{http://www.tei-c.org/ns/1.0}abstract")

    if abstract is None or abstract.text is None:
      no_abstract_files.append(filename)

for file in no_abstract_files:
    os.remove(os.path.join(articles_directory, file))
