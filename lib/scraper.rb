require 'net/http'
require 'nokogiri'
require 'uri'

class Scraper
  attr_reader :base_url, :logger

  def initialize(base_url, logger)
    @base_url = base_url
    @logger = logger
  end

  # Public method to start the scraping process
  def scrape(paths = ['/'], progress_callback = nil)
    all_data = []
    total_pages = paths.size
    current_page = 0
    urls_used = []

    paths.each do |path|
      current_page += 1

      url = build_url(path)
      logger.info("Scraping URL: #{url}")
      urls_used << url

      html = fetch_html(url)
      next if html.nil?

      page_data = extract_info_from_page(html, url)
      all_data << page_data

      new_links = page_data[:links]
      next_paths = normalize_links(new_links)
      progress_callback.call(current_page, total_pages) if progress_callback

      all_data.concat(scrape(next_paths, progress_callback)) unless next_paths.empty?
    end

    return all_data, urls_used
  end

  private

  # Function to make an HTTP request and retrieve the HTML content
  def fetch_html(url)
    logger.debug("Fetching HTML for URL: #{url}")
    uri = URI.parse(url)
    response = Net::HTTP.get_response(uri)
    logger.debug("Response status: #{response.code}")
    Nokogiri::HTML(response.body)
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
    internal_links = html.css('a').map { |link| link['href'] }.compact.select { |href| href.start_with?('/') }
    page_data[:links] = internal_links.empty? ? [] : internal_links
    logger.debug("Links extracted: #{internal_links.count}")

    page_data
  rescue => e
    logger.error("Failed to extract information from URL #{url}: #{e.message}")
    {}
  end

  # Function to normalize relative and absolute links correctly
  def normalize_links(new_links)
    new_links.map do |link|
      if link.start_with?('/') # Relative
        URI.join(base_url, link).to_s
      else
        link # Already absolute
      end
    end.uniq
  end

  # Function to build absolute URL from the base URL and path
  def build_url(path)
    if path.start_with?('http')
      path  # It is already an absolute URL
    else
      URI.join(@base_url, path).to_s  # Relative URL, so join with base_url
    end
  end
end
