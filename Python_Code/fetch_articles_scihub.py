# Master's thesis Psychology
# University of Zurich
# Author: Berit Barthelmes

# set up selenium
from webdriver_manager.chrome import ChromeDriverManager
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium import webdriver
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.by import By
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
  driver = webdriver.Chrome(service=ChromeService(ChromeDriverManager().install()), options=options)
  return driver


def driver_wait(driver, tag, time):
  element = WebDriverWait(driver, time).until(EC.visibility_of_element_located((By.CSS_SELECTOR, tag)))
  return element


def fetch_articles_scihub(dois):
  driver = get_driver()
  scihub_url = "https://sci-hub.se"

  for doi in dois:
    driver.get(f"{scihub_url}/{doi}")
    
    embedded_pdf = None
    try:
      embedded_pdf = driver_wait(driver, "embed[type='application/pdf']", 5)
    except:
      pass
    if embedded_pdf:
      pdf_url = embedded_pdf.get_attribute("src")
      if pdf_url:
        driver.get(pdf_url)
        sleep(2)
