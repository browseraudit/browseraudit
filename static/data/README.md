# Test Data Archives

This repository contains zipped CSV files of test suite execution data, organized by year.

### How to Unzip the Files

To extract the data for a specific year, use a standard unzip command. For example, to unzip the `2024.zip` file:

```bash
unzip 2024.zip
```

This will create two files: `2024-suite.csv` and `2024-test.csv`.

### Data File Descriptions

#### `*-suite.csv`

This file contains records of each test suite execution.

| **Field**    | **Description**                                            |
| :----------- | :--------------------------------------------------------- |
| `id`         | The unique identifier for the test suite execution.        |
| `timestamp`  | The UTC timestamp when the execution was run.              |
| `user_agent` | The user agent string from the browser that ran the tests. |

**Sample Data (`2024-suite.csv`)**

| **id** | **timestamp**          | **user_agent**                                                                                                        |
| :----- | :--------------------- | :-------------------------------------------------------------------------------------------------------------------- |
| 10245  | 2024-01-10 09:30:00+00 | Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 |
| 10246  | 2024-01-10 10:45:00+00 | Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/120.0.2210.121 Safari/537.36    |

#### `*-test.csv`

This file contains the individual test outcomes for each suite execution.

| **Field** | **Description**                                           |
| :-------- | :-------------------------------------------------------- |
| `id`      | The identifier of the parent test suite execution.        |
| `test_id` | The unique identifier for the specific test that was run. |
| `outcome` | The result of the test (e.g., `PASS`, `FAIL`, `SKIP`).    |

**Sample Data (`2024-test.csv`)**

| **id** | **test_id** | **outcome** |
| :----- | :---------- | :---------- |
| 10245  | 126         | PASS        |
| 10245  | 127         | FAIL        |
| 10246  | 412         | PASS        |

### Test Descriptions

For a full description of each test, refer to the `postgres/testsuite.sql` file in [the BrowserAudit repo](https://github.com/browseraudit/browseraudit). The `test_id` field in the `*-test.csv` files corresponds to the `id` field of the `test` table populated in `postgres/testsuite.sql`.
