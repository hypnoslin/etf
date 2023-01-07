from selenium import webdriver
from bs4 import BeautifulSoup

# Desired URL
url = "https://www.kgifund.com.tw/Fund/Detail?fundID=J015"

# create a new Firefox session
driver = webdriver.Chrome()
driver.implicitly_wait(30)
driver.get(url)

# Pass to BS4
soup = BeautifulSoup(driver.page_source, features="html.parser")

# Find all the div elements with the class 'content'
tds = soup.find_all("tr", {"name":"content"})

# Print the contents of the tds
for td in tds:
    print(td.text)

driver.close()
