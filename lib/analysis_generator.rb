require 'net/http'
require 'json'

class AnalysisGenerator
  attr_reader :logger

  def initialize(logger)
    @logger = logger
  end

  # Public method to generate insights
  def generate_insights(data, urls_used)
    logger.info("Sending data to ChatGPT...")
    response = send_to_chatgpt(data)
    chatgpt_response = parse_chatgpt_response(response)

    save_insights(chatgpt_response, urls_used)
    logger.info("Insights generated and saved in 'chatgpt_insights.txt'")
  end

  private

  # Function to send data to ChatGPT
  def send_to_chatgpt(data)
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

    logger.debug("ChatGPT API response status: #{response.code}")
    response
  end

  # Function to parse the response from ChatGPT
  def parse_chatgpt_response(response)
    JSON.parse(response.body)["choices"][0]["message"]["content"]
  end

  # Function to save insights and URLs to a file
  def save_insights(chatgpt_response, urls_used)
    Dir.mkdir('data') unless Dir.exist?('data')

    File.open("data/chatgpt_insights.txt", "w") do |file|
      file.puts chatgpt_response
      file.puts "\nReferences for URLs used:\n"
      urls_used.each do |url|
        file.puts url
      end
    end
  end
end
