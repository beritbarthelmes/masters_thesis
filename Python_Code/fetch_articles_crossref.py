# Master's thesis Psychology
# University of Zurich
# Author: Berit Barthelmes
# 04-20-2023

from crossref.restful import Works
from selenium import webdriver
from time import sleep

# build web driver, which operates on Chrome automatically, visible
def get_driver():
  options = webdriver.ChromeOptions()
  options.add_argument('--disable-logging')
  options.add_argument('--ignore-certificate-errors')
  options.add_argument('--ignore-ssl-errors')
  options.add_experimental_option('prefs',  {
    "download.prompt_for_download": False,
    "download.directory_upgrade": True,
    "plugins.always_open_pdf_externally": True
    }
  )
  driver = webdriver.Chrome(options=options)
  return driver

def fetch_articles_crossref(dois):
  driver = get_driver()

  works = Works()
  for doi in dois:
    article = works.doi(doi)
    if article["link"]:
      pdf_link = None

      try:
        pdf_link = next(link for link in article["link"] if link["content-type"] == "application/pdf")
      except:
        pass

      if pdf_link:
        driver.get(pdf_link["URL"])
        sleep(3)
