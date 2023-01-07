from selenium import webdriver
from bs4 import BeautifulSoup

# Desired URL
url = "https://www.yuantaetfs.com/product/detail/00713/ratio"

# create a new Firefox session
driver = webdriver.Chrome()
driver.implicitly_wait(30)
driver.get(url)

# Get button and click it
python_button = driver.find_element_by_class_name("moreBtn")
python_button.click() #click load more button

# Pass to BS4
soup = BeautifulSoup(driver.page_source, features="html.parser")

# Find all the div elements with the class 'content'
tds = soup.find_all('div', class_='td')

# Print the contents of the tds
for td in tds:
    print(td.text)

driver.close()
