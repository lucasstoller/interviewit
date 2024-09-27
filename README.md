# InterviewIt

**InterviewIt** is a Ruby application that generates analyses of companies you're being interviewed for using web scraping and AI. The app fetches public data from a company's website and leverages AI to generate a detailed report, which is saved as a text file.

## Features

- Fetches company information via web scraping using `Nokogiri`.
- Generates a comprehensive analysis using AI with OpenAI's API.
- Saves the analysis in a text file for future reference.
- Logs all scraping and analysis activities for easy tracking.
- Customizable environment variables for dynamic usage.

## Prerequisites

- Ruby (>= 3)
- You do **not** need to install anything manually. Simply run `bundle install` to install all required gems.

```bash
bundle install
```

## Environment Variables

To run the app, you need to set up the following environment variables by creating a `.env` file in the root directory:

```env
INSTITUTIONAL_COMPANY_BASE_URL=https://example-company.com
OPEN_AI_API_KEY=your-openai-api-key
LOG_LEVEL=debug
URLS_LIMIT=10
```

- **INSTITUTIONAL_COMPANY_BASE_URL**: The base URL of the company's website to be scraped.
- **OPEN_AI_API_KEY**: Your API key for OpenAI to generate the analysis.
- **LOG_LEVEL**: Sets the level of logging (e.g., `debug`, `info`, `error`).
- **URLS_LIMIT**: Sets the maximum number of URLs to scrape from the company site.

## Usage

### Initialize the Scraper

To begin scraping and generating a report, simply initialize the `Scraper` class with the necessary parameters.

```ruby
require 'logger'
require './scraper'

# Initialize the logger
logger = Logger.new(STDOUT)

# Initialize the Scraper
scraper = Scraper.new(ENV['INSTITUTIONAL_COMPANY_BASE_URL'], logger)
```

### Generate Company Analysis

Once you've initialized the scraper, you can start the process by calling the `scrape` method:

```ruby
scraper.scrape(['/'])
```

The app will fetch data from the company website, process it with AI, and generate an analysis saved in the `data` folder.

### Example Output

After running the scraper and AI analysis, the final analysis is saved as a `.txt` file in the `data` folder. The report includes detailed insights based on the company's public information.

Example of the file structure:

```bash
data/
  analysis_companyname.txt
```

### Logs

All logs for scraping and processing activities are saved in the `logs` folder. This can help in debugging or reviewing the process flow.

Example of the log file structure:

```bash
logs/
  app.log
```

## Error Handling

The app handles HTTP errors and logs any failed attempts to fetch a page. If an error occurs while retrieving or analyzing the data, the error will be recorded in the log file.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
