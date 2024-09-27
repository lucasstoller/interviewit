require 'net/http'
require 'nokogiri'
require 'uri'

class Scraper
  attr_reader :base_url, :logger, :urls_used, :execution_duration

  URLS_LIMIT = ENV['URLS_LIMIT'] || 5

  def initialize(base_url, logger)
    @base_url = base_url
    @logger = logger
    @urls_used = []
  end

  # Public method to start the scraping process
  def scrape(urls = [@base_url], start_time = Time.now)
    if urls.empty? || @urls_used.size == URLS_LIMIT
      @execution_duration = Time.now - start_time
      return []
    end

    first_url, *other_urls = urls

    logger.info("Scraping URL: #{first_url}")
    @urls_used << first_url

    html = fetch_html(first_url)
    return scrape(other_urls, start_time) unless html

    page_data = extract_info_from_page(html, first_url)
    other_urls = merge_new_urls(other_urls, page_data[:links])

    log_progress(other_urls)

    [page_data].concat(scrape(other_urls, start_time))  # Recursively scrape new URLs
  end

  private

  def log_progress(other_urls)
    total_url_size = @urls_used.size + other_urls.size
    percent_complete = @urls_used.size.to_f / total_url_size * 100
    @logger.info("Scraped #{@urls_used.size}/#{total_url_size} - #{percent_complete}%")
  end

  def merge_new_urls(urls, new_urls = [])
    merged_urls = (urls + new_urls).uniq

    @logger.info("#{merged_urls.size - urls.size} urls added into the stack")

    merged_urls
  end

  # Function to make an HTTP request and retrieve the HTML content
  def fetch_html(url)
    logger.debug("Fetching HTML for URL: #{url}")
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)

    if response.is_a?(Net::HTTPSuccess)
      Nokogiri::HTML(response.body)
    else
      logger.error("Failed to fetch HTML for URL #{url}: HTTP #{response.code}")
      nil
    end
  rescue => e
    logger.error("Failed to fetch HTML for URL #{url}: #{e.message}")
    nil
  end

  # Function to extract information from the HTML
  def extract_info_from_page(html, url)
    logger.debug("Extracting information from URL: #{url}")
    page_data = {}

    # Extracting the page title
    title = html.css('title').text
    page_data[:title] = title unless title.empty?
    logger.debug("Title extracted: #{title}")

    # Extracting all paragraphs
    paragraphs = html.css('p').map(&:text)
    page_data[:paragraphs] = paragraphs unless paragraphs.empty?
    logger.debug("Paragraphs extracted: #{paragraphs.count}")

    # Include the page URL in the data
    page_data[:url] = url

    # Extracting internal links
    internal_links = html.css('a').map { |link| normalize_link(link['href']) }.compact.select do |href|
      href.match?(%r{^(/|#{@base_url})([^#]*)$}) && href != @base_url && href != "#{@base_url}/"
    end.uniq
    page_data[:links] = internal_links
    logger.debug("Links extracted: #{internal_links.count}")

    page_data
  rescue => e
    logger.error("Failed to extract information from URL #{url}: #{e.message}")
    {}
  end

  # Function to build absolute URL from the base URL and path
  def normalize_link(link)
    return if link.nil?

    if link.start_with?('http')
      link  # It is already an absolute URL
    else
      URI.join(@base_url, link).to_s  # Relative URL, so join with base_url
    end
  end
end
