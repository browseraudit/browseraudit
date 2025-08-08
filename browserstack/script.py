import json
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

# Launch the browser and navigate to BrowserAudit.com
driver = webdriver.Chrome() # Driver will be overwritten by BrowserStack config file
driver.get('https://browseraudit.com')

# Find and click the "Test Me" button
test_me_button = WebDriverWait(driver, 10).until(
    EC.element_to_be_clickable((By.CSS_SELECTOR, '.btn.btn-primary.btn-lg.browseraudit-start'))
)
test_me_button.click()

# Wait until the test results link appears
test_results_link = WebDriverWait(driver, 300).until(
    EC.presence_of_element_located((By.LINK_TEXT, 'this link'))
)

# Get the href attribute of the test results link
test_report_link = test_results_link.get_attribute('href')

# Print the test report link for review
print('Test Report Link:', test_report_link)

# Set the status of the session to "passed" if link retrieved successfuly
if ("result" in test_report_link):
  executor_object = {
      'action': 'setSessionStatus',
      'arguments': {
          'status': "passed",
          'reason': "Test suite completed and results link retrieved"
      }
  }
  browserstack_executor = 'browserstack_executor: {}'.format(json.dumps(executor_object))
  driver.execute_script(browserstack_executor)

# Close the browser
driver.quit()
