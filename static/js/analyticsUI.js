/* Identifies browser string and version from user agent */
function extractBrowser(userAgent) {
  const browserRegex = /(firefox|msie|chrome|safari|trident(?=\/))\/?\s*(\d+(\.\d+)?)/i;
  const match = userAgent.match(browserRegex);

  if (match) {
    const browser = match[1].toLowerCase();
    const version = match[2];
    return `${browser} (${version})`;
  }

  return userAgent;
}

/* Fetches data from a URL and applies given data processing function to it */
function fetchChartData(url, processData) {
  fetch(url)
    .then((response) => response.json())
    .then((data) => {
      hideLoader(url);
      processData(data);
    })
    .catch((error) => {
      console.error("Error loading chart data:", error);
      hideLoader(url);
    });
}

/* Helper Function to create a bar chart with preset customisations */
function createBarChart(yLabels, yTitle, xTitle, data, id) {
  var chartData = {
    labels: yLabels,
    datasets: [
      {
        data: data,
        backgroundColor: "rgba(75, 192, 192, 0.2)",
        borderColor: "rgba(75, 192, 192, 1)",
        borderWidth: 2,
      },
    ],
  };

  // Chart options
  var options = {
    plugins: {
      legend: {
        display: false,
      },
    },
    responsive: true,
    scales: {
      x: {
        title: {
          display: true,
          text: xTitle,
          font: {
            weight: "bold",
          },
        },
      },
      y: {
        ticks: {
          beginAtZero: true,
        },
        title: {
          display: true,
          text: yTitle,
          font: {
            weight: "bold",
          },
        },
      },
    },
  };

  var ctx = document.getElementById(id).getContext("2d");
  var myChart = new Chart(ctx, {
    type: "bar",
    data: chartData,
    options: options,
  });
}

/* Loader IDs are taken from the request URL for simplicity */
function hideLoader(requestUrl) {
  var pattern = /^\/analytics\/(.*)$/;
  var match = requestUrl.match(pattern);

  if (match && match.length > 1) {
    var extractedString = match[1];
    var loader = document.getElementById(extractedString + "Loader");
    if (loader) {
      loader.style.display = "none";
    }
  }
}

/* Fetches overview data and updates the given cell within the overview table */
function updateOverviewTable(url, cellId) {
  fetch(url)
    .then((response) => response.json())
    .then((data) => {
      const cell = document.getElementById(cellId);
      cell.textContent = data.result.toLocaleString(); // Update the cell with the fetched data
    })
    .catch((error) => {
      console.error("Error fetching data:", error);
    });
}

function displayErrorMessage(canvasId) {
  const canvas = document.getElementById(canvasId);
  const context = canvas.getContext("2d");

  const devicePixelRatio = window.devicePixelRatio || 1;

  // Get the CSS size of the canvas
  const rect = canvas.getBoundingClientRect();

  // Set the canvas's internal dimensions to scale for the device pixel ratio
  canvas.width = rect.width * devicePixelRatio;
  canvas.height = rect.height * devicePixelRatio;

  // Scale the context to match the CSS size, so everything is drawn correctly
  context.scale(devicePixelRatio, devicePixelRatio);

  context.font = "18px Arial";
  context.fillStyle = "red";
  context.textAlign = "center";
  context.fillText("Error retrieving data from cache", rect.width / 2, rect.height / 2);
}

// Create the charts

/* Monthly test executions for last 12 months line graph */
fetchChartData("/analytics/monthlyExecutions", (data) => {
  data.month_year.pop(); // removing current month as it's incomplete, and looks like an anomaly
  data.execution_count.pop();
  var data = {
    labels: data.month_year,
    datasets: [
      {
        data: data.execution_count,
        borderColor: "blue",
        fill: false,
      },
    ],
  };

  // Configuration options
  var options = {
    plugins: {
      legend: {
        display: false,
      },
    },
    scales: {
      x: {
        ticks: {
          autoSkip: true,
          maxRotation: 90,
          minRotation: 90,
        },
        title: {
          display: true,
          text: "Month",
          font: {
            weight: "bold",
          },
        },
      },
      y: {
        ticks: {
          beginAtZero: true,
        },
        title: {
          display: true,
          text: "Number of Executions",
          font: {
            weight: "bold",
          },
        },
      },
    },
  };

  // Create the line graph
  var ctx = document.getElementById("monthlyTestLine").getContext("2d");
  var myChart = new Chart(ctx, {
    type: "line",
    data: data,
    options: options,
  });
});

fetchChartData("/analytics/monthlyFails", (data) => {
  if (data.error) {
    displayErrorMessage("monthlyFailsLine");
    return;
  }

  // remove current (incomplete) month
  data.month_year.pop();
  data.critical_test_count.pop();
  //data.unique_test_count.pop();

  var chartData = {
    labels: data.month_year,
    datasets: [
      {
        label: "Count of total test failures",
        data: data.critical_test_count,
        borderColor: "blue",
        //  yAxisID: 'lx_total', // uncomment this for two lines, two axis
        fill: false,
      },
      // /* Uncomment below for two lines, two axis */
      // {
      //   label: 'Number of unique tests failing',
      //   data: data.unique_test_count,
      //   borderColor: 'purple',
      //   yAxisID: 'rx_unique',
      //   fill: false
      // }
    ],
  };

  var options = {
    plugins: {
      legend: { display: false }, // now show the legend so users know which line is which
    },
    scales: {
      x: {
        ticks: { autoSkip: true, maxRotation: 90, minRotation: 90 },
        title: { display: true, text: "Month", font: { weight: "bold" } },
      },
      y: {
        ticks: {
          beginAtZero: true,
        },
        title: {
          display: true,
          text: "Number of Executions",
          font: {
            weight: "bold",
          },
        },
      },
      // /* Uncomment below, and comment 'y' above to show two lines, two axis */
      // lx_total: {                       // left y-axis
      //   type: 'linear',
      //   display: true,
      //   position: 'left',
      //   title: {
      //     display: true,
      //     text: 'Total failures',
      //     color:'blue',
      //     font: { weight: 'bold' }
      //   },
      //   beginAtZero: true
      // },
      // rx_unique: {                      // right y-axis
      //   type: 'linear',
      //   display: true,
      //   position: 'right',
      //   title: {
      //     display: true,
      //     text: 'Unique failures',
      //     color: 'purple',
      //     font: { weight: 'bold' }
      //   },
      //   beginAtZero: true,

      //   // make the grid lines for this axis transparent so it doesn't clash
      //   grid: { drawOnChartArea: false }
      // }
    },
  };

  var ctx = document.getElementById("monthlyFailsLine").getContext("2d");
  new Chart(ctx, { type: "line", data: chartData, options: options });
});

/* Average Duration by Category Bar Chart */
fetchChartData("/analytics/catDuration", (data) => {
  createBarChart(
    data.title,
    "Average Duration (ms)",
    "Category",
    data.average_duration.map(Number),
    "durationBarChart",
  );
});

/* Top User Agents Bar Chart */
fetchChartData("/analytics/topUserAgents", (data) => {
  createBarChart(
    data.user_agent.map(extractBrowser),
    "Number of Executions",
    "User Agent",
    data.user_agent_count.map(Number),
    "topUserAgentsBarChart",
  );
});

/* Top 5 Failing Sub-Categories */
fetchChartData("/analytics/subcatTopFail", (data) => {
  if (data.error) {
    displayErrorMessage("subcatTopFailBarChart");
  } else {
    createBarChart(data.title, "Fail Ratio", "Sub-Category", data.failing_test_ratio, "subcatTopFailBarChart");
  }
});

/* Test Fail Ratios by Category */
fetchChartData("/analytics/catFailRatio", (data) => {
  if (data.error) {
    displayErrorMessage("catFailRatioChart");
  } else {
    createBarChart(data.title, "Fail Ratio", "Category", data.averaged_fail_ratio, "catFailRatioChart");
  }
});

/* Test Skip Ratios by Category */
fetchChartData("/analytics/catSkipRatio", (data) => {
  if (data.error) {
    displayErrorMessage("catSkipRatioChart");
  } else {
    createBarChart(data.title, "Skip Ratio", "Category", data.averaged_skip_ratio, "catSkipRatioChart");
  }
});

/* Top Failure Ratios by User Agent */
fetchChartData("/analytics/topUserAgentFailRatio", (data) => {
  if (data.error) {
    displayErrorMessage("topUserAgentFailureRatio");
  } else {
    createBarChart(
      data.user_agent.map(extractBrowser),
      "Fail Ratio",
      "User Agent",
      data.failure_ratio,
      "topUserAgentFailureRatio",
    );
  }
});

/* Display Mode Pie Chart */
/* This statistics not interesting at the moment.
fetchChartData("/analytics/displayModePercentages", (data) => {
  // Chart data
  var pieData = {
    labels: data.display_mode,
    datasets: [
      {
        backgroundColor: ["rgba(255, 99, 132, 0.2)", "rgba(54, 162, 235, 0.2)", "rgba(255, 206, 86, 0.2)"],
        borderColor: ["rgba(255, 99, 132, 1)", "rgba(54, 162, 235, 1)", "rgba(255, 206, 86, 1)"],
        borderWidth: 1,
        data: data.percentage.map(Number),
      },
    ],
  };

  // Create the chart
  var ctx = document.getElementById("displayModePieChart").getContext("2d");
  var myChart = new Chart(ctx, {
    type: "pie",
    data: pieData,
    options: {
      responsive: true,
      maintainAspectRatio: false,
    },
  });
});
*/

// Fetch data for each row and update the respective overview table row
updateOverviewTable("/analytics/totalTests", "totalTestsRow");
updateOverviewTable("/analytics/totalTestsExecuted", "totalTestsExecutedRow");
updateOverviewTable("/analytics/uniqueUserAgents", "UniqueUserAgentsRow");
updateOverviewTable("/analytics/lastMonthTests", "lastMonthTestsRow");
updateOverviewTable("/analytics/lastMonthTestsExecuted", "lastMonthTestsExecutedRow");
updateOverviewTable("/analytics/lastMonthUniqueUserAgents", "lastMonthUniqueUserAgentsRow");
