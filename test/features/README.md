# Hologram Feature Tests App
  
To find all available pages and their routes:
  * Run `mix holo.routes`
  
To start the server:
  * Run `mix deps.get` to install the dependencies
  * Run `mix phx.server`
  
Now you can visit [`localhost:4000`](http://localhost:4000) from your browser (remember about appending your chosen page path to the URL).

To run the tests:
  * Run `mix deps.get` to install the dependencies
  * Run `mix playwright.install chromium` to install the browser the tests drive
  * Run `mix test`; a failed test leaves its trace and screenshot in `test-results/`

CI also uploads `report.json` and, when it retries failed tests, `report-retry.json` alongside the failure artifacts.
