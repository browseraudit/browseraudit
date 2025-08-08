# BrowserAudit database
## Configuration
The PostgreSQL configuration is automated by `docker`. The data volume is persistent, so the database is created once and for all. 

## Test suite
File `testsuite.sql` contains a snapshot of the tests currently used by BrowserAudit, so it can be used as a reference. It is used when the dataset is createda to initialise the test suite. Development updates should be done on the live database instance, not on this file.