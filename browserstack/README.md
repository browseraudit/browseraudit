# Automated testing with BrowserStack

BrowserStack can run the BrowserAudit test suite on different browsers and platforms automatically.
This is independent from Browseraudit development, and runs directly with the production [https://browseraudit.com](https://browseraudit.com) website. Alternatively, you can personalise `script.py` to run against your own fork of BrowserAudit, but you will need to handle the different domain names needed in order for Browserstack to access your deployment.

## Requirements

- In order to run automatic tests, you need to have a [BrowserStack](https://www.browserstack.com/) account.
- You need `python` to run the tests (tested on Python 3.9.6).
- Install requirements: `pip3 install -r requirements.txt`

## Configure

- Copy `browserstack.yml-dist` to `browserstack.yml`
- Copy `userName` and `accessKey` key from [https://www.browserstack.com/accounts/settings](https://www.browserstack.com/accounts/settings) to `browserstack.yml`
- Additional information on configuring `browserstack.yml` can be found here: https://www.browserstack.com/docs/

## Run the tests

- Run `browserstack-sdk python3 ./script.py`
- You can view the results of the test in your BrowserStack dashboard.
