const http = require('http');

function checkHealth(urlToCheck, interval, maxRetries) {
  let retryCount = 0;

  const healthCheck = () => {
    http.get(urlToCheck, res => {
      const { statusCode } = res;

      if (statusCode === 200) {
        console.log('Health-check passed!');
        process.exit(0);
      } else {
        retryCount++;
        console.log(`Health-check failed, retry count: ${retryCount}`);
      }
    }).on('error', () => {
      retryCount++;
      console.log(`Health-check failed, retry count: ${retryCount}`);
    });

    if (retryCount === maxRetries) {
      console.log(`Health-check failed after ${maxRetries} retries.`);
      clearInterval(healthCheck);
      process.exit(1);
    }
  };

  healthCheck();
  setInterval(healthCheck, interval * 1000);
}

const args = process.argv.slice(2);
const urlToCheck = args[0];
const interval = parseInt(args[1], 10);
const maxRetries = parseInt(args[2], 10);

checkHealth(urlToCheck, interval, maxRetries);
