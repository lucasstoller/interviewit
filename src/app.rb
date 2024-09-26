require 'net/http'
require 'nokogiri'
require 'json'
require 'uri'
require 'dotenv/load'

# Function to make an HTTP request and retrieve the HTML content
def fetch_html(url)
  uri = URI.parse(url)
  response = Net::HTTP.get_response(uri)
  Nokogiri::HTML(response.body)
end

# Function to extract information from the HTML
def extract_info_from_page(html, url)
  page_data = {}
  
  # Example: Extracting the page title
  title = html.css('title').text
  page_data[:title] = title unless title.empty?

  # Example: Extracting all paragraphs
  paragraphs = html.css('p').map(&:text)
  page_data[:paragraphs] = paragraphs unless paragraphs.empty?

  # Include the page URL in the data
  page_data[:url] = url

  # Example: Extracting internal links
  internal_links = html.css('a').map { |link| link['href'] }.compact.select { |href| href.start_with?('/') }
  page_data[:links] = internal_links.empty? ? [] : internal_links

  page_data
end

# Function to follow internal links and collect information
def scrape_site(base_url, paths = ['/'], progress_callback = nil)
  all_data = []
  total_pages = paths.size
  current_page = 0
  urls_used = []

  paths.each do |path|
    current_page += 1

    # Check if the path is already an absolute URL or a relative one
    url = if path.start_with?('http')
            path  # It is already an absolute URL
          else
            URI.join(base_url, path).to_s  # Relative URL, so join with base_url
          end

    puts "Scraping URL: #{url}"
    urls_used << url  # Store the URL for future reference

    html = fetch_html(url)
    page_data = extract_info_from_page(html, url) # Pass the URL for reference

    all_data << page_data

    # Retrieve new links to follow
    new_links = page_data[:links]

    # Normalize relative and absolute links correctly
    next_paths = new_links.map do |link|
      if link.start_with?('/') # Relative
        URI.join(base_url, link).to_s
      else
        link # Already absolute
      end
    end.uniq

    # Update progress
    progress_callback.call(current_page, total_pages) if progress_callback

    # Recursively follow links
    all_data.concat(scrape_site(base_url, next_paths, progress_callback)) unless next_paths.empty?
  end

  return all_data, urls_used
end

# Function to show progress
def show_progress(current, total)
  percent_complete = ((current.to_f / total.to_f) * 100).round(2)
  puts "Progress: #{percent_complete}% (#{current} of #{total} pages processed)"
end

# Function to send collected data to ChatGPT and generate insights
def generate_insights(data, urls_used)
  puts "Sending data to ChatGPT..."

  api_key = ENV['OPEN_AI_API_KEY'] # Put your API key here
  uri = URI("https://api.openai.com/v1/chat/completions")

  # Prepare the data in JSON format to send
  prompt = "Here is some data extracted from an institutional site: #{data.to_json}. Generate relevant insights for an interview, such as values, recent projects, company culture, and topics I can discuss. The references for each analysis are linked to their respective URLs."

  request_body = {
    model: "gpt-4",
    messages: [
      { role: "system", content: "You are an assistant helping to generate insights from information extracted from an institutional site." },
      { role: "user", content: prompt }
    ],
    max_tokens: 500,
    temperature: 0.7
  }.to_json

  # Make a POST request to the ChatGPT API
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.path, {
    "Content-Type" => "application/json",
    "Authorization" => "Bearer #{api_key}"
  })
  request.body = request_body
  response = http.request(request)

  # Get the response from ChatGPT
  chatgpt_response = JSON.parse(response.body)["choices"][0]["message"]["content"]
  
  # Save the response in a .txt file
  File.open("chatgpt_insights.txt", "w") do |file|
    file.puts chatgpt_response
    file.puts "\nReferences for URLs used:\n"
    urls_used.each do |url|
      file.puts url
    end
  end

  puts "Insights generated and saved in 'chatgpt_insights.txt'"
end

# URL of the company site
base_url = ENV['INSTITUTIONAL_COMPANY_BASE_URL'] # Put the company's URL here

puts "Starting the scraping process..."

# Collect the site's information with progress tracking
site_data, urls_used = scrape_site(base_url, ['/'], method(:show_progress))

puts "Scraping completed. Generating insights with ChatGPT..."

# Generate insights using ChatGPT and save to the file, including URLs used
generate_insights(site_data, urls_used)

puts "Process completed!"