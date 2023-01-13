from selenium import webdriver
from bs4 import BeautifulSoup

# Desired URL
url = "https://www.cathaysite.com.tw/fund-details/ECN?tab=portfolio"

# create a new Firefox session
driver = webdriver.Chrome()
driver.implicitly_wait(60)
driver.get(url)

# Pass to BS4
soup = BeautifulSoup(driver.page_source, features="html.parser")

# Find all the div elements with the class 'content'
# tds = soup.find_all("div", {"id":"portfolio"})
tds = soup.find_all("ul", {"class":"bar-chart-ul ng-star-inserted"})

# Print the contents of the tds
for td in tds:
    print(td.text)

driver.close()
