from selenium import webdriver
from bs4 import BeautifulSoup
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.common.by import By
from selenium.webdriver.support import expected_conditions as EC

# Desired URL
url = "https://www.cathaysite.com.tw/fund-details/ECN?tab=portfolio"

# create a new Firefox session
driver = webdriver.Chrome()
driver.implicitly_wait(30)
driver.get(url)

try:
    WebDriverWait(driver, 30).until(
            EC.presence_of_element_located
            (
                (By.XPATH,
                    '//*[@id="portfolio"]/app-portfolio/div[1]/div/div[1]/div[2]/div[1]/ul')
                )
            )
finally:

# Pass to BS4
    soup = BeautifulSoup(driver.page_source, features="html.parser")

# Find all the div elements with the class 'content'
    tds = soup.find_all("ul", {"class":"bar-chart-ul ng-star-inserted"})

# Print the contents of the tds
    for td in tds:
        print(td.text)

    driver.close()
