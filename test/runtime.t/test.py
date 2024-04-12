#!/usr/bin/env python

# pip install selenium
# brew install chromedriver

import sys
import os
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.wait import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC


def click(link):
    WebDriverWait(driver, 10).until(
        EC.presence_of_element_located((By.LINK_TEXT, link))
    ).click()


with webdriver.Chrome() as driver:
    # driver.get(f"file://{os.getcwd()}/index.html")
    driver.get(f"file://{os.getcwd()}/{os.getenv('INPUT')}")
    for link in sys.argv[1:]:
        click(link)
    print(driver.find_element(By.ID, "content").get_attribute("innerHTML"))
