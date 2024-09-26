class Application
  def initialize
    @logger = LoggerConfig.build_logger
    @scraper = Scraper.new(ENV['INSTITUTIONAL_COMPANY_BASE_URL'], @logger)
    @analysis_generator = AnalysisGenerator.new(@logger)
  end

  def run
    @logger.info("Starting the scraping process...")

    # Collect the site's information with progress tracking
    site_data, urls_used = @scraper.scrape(['/'], method(:show_progress))

    @logger.info("Scraping completed. Generating insights with ChatGPT...")

    # Generate insights using ChatGPT and save to the file, including URLs used
    @analysis_generator.generate_insights(site_data, urls_used)

    @logger.info("Process completed!")
  end

  # Function to show progress
  def show_progress(current, total)
    percent_complete = ((current.to_f / total.to_f) * 100).round(2)
    @logger.info("Progress: #{percent_complete}% (#{current} of #{total} pages processed)")
  end
end