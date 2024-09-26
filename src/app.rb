require 'net/http'
require 'nokogiri'
require 'json'
require 'uri'
require 'dotenv/load'

# Função para fazer requisição HTTP e obter o conteúdo HTML
def fetch_html(url)
  uri = URI.parse(url)
  response = Net::HTTP.get_response(uri)
  Nokogiri::HTML(response.body)
end

# Função para extrair informações do HTML
def extract_info_from_page(html, url)
  page_data = {}
  
  # Exemplo: Extraindo o título da página
  title = html.css('title').text
  page_data[:title] = title unless title.empty?

  # Exemplo: Extraindo todos os parágrafos
  paragraphs = html.css('p').map(&:text)
  page_data[:paragraphs] = paragraphs unless paragraphs.empty?

  # Incluir o URL da página nos dados
  page_data[:url] = url

  # Exemplo: Extraindo links internos
  internal_links = html.css('a').map { |link| link['href'] }.compact.select { |href| href.start_with?('/') }
  page_data[:links] = internal_links.empty? ? [] : internal_links

  page_data
end

# Função para seguir links internos e coletar informações
def scrape_site(base_url, paths = ['/'], progress_callback = nil)
  all_data = []
  total_pages = paths.size
  current_page = 0
  urls_used = []

  paths.each do |path|
    current_page += 1

    # Verificar se o caminho já é uma URL absoluta ou relativa
    url = if path.start_with?('http')
            path  # Já é uma URL absoluta
          else
            URI.join(base_url, path).to_s  # URL relativa, então unir com base_url
          end

    puts "Scraping URL: #{url}"
    urls_used << url  # Guardando o URL para referência futura

    html = fetch_html(url)
    page_data = extract_info_from_page(html, url) # Passar o URL para referência

    all_data << page_data

    # Pegar novos links para seguir
    new_links = page_data[:links]

    # Normalizando links relativos e absolutos corretamente
    next_paths = new_links.map do |link|
      if link.start_with?('/') # Relativo
        URI.join(base_url, link).to_s
      else
        link # Já é absoluto
      end
    end.uniq

    # Atualizar progresso
    progress_callback.call(current_page, total_pages) if progress_callback

    # Recursivamente seguir links
    all_data.concat(scrape_site(base_url, next_paths, progress_callback)) unless next_paths.empty?
  end

  return all_data, urls_used
end

# Função para exibir progresso
def show_progress(current, total)
  percent_complete = ((current.to_f / total.to_f) * 100).round(2)
  puts "Progresso: #{percent_complete}% (#{current} de #{total} páginas processadas)"
end

# Função para enviar dados coletados para o ChatGPT e gerar insights
def generate_insights(data, urls_used)
  puts "Enviando dados para o ChatGPT..."

  api_key = ENV['OPEN_AI_API_KEY'] # Coloque sua chave API aqui
  uri = URI("https://api.openai.com/v1/chat/completions")

  # Preparar os dados em formato JSON para enviar
  prompt = "Aqui estão alguns dados extraídos de um site institucional: #{data.to_json}. Gere insights relevantes para uma entrevista, como valores, projetos recentes, cultura da empresa, e tópicos que posso discutir. As referências de cada análise estão nos respectivos URLs."

  request_body = {
    model: "gpt-4",
    messages: [
      { role: "system", content: "Você é um assistente que ajuda a gerar insights a partir de informações extraídas de um site institucional." },
      { role: "user", content: prompt }
    ],
    max_tokens: 500,
    temperature: 0.7
  }.to_json

  # Fazendo requisição POST para a API do ChatGPT
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  request = Net::HTTP::Post.new(uri.path, {
    "Content-Type" => "application/json",
    "Authorization" => "Bearer #{api_key}"
  })
  request.body = request_body
  response = http.request(request)

  # Pegando a resposta do ChatGPT
  chatgpt_response = JSON.parse(response.body)["choices"][0]["message"]["content"]
  
  # Salvando a resposta em um arquivo .txt
  File.open("chatgpt_insights.txt", "w") do |file|
    file.puts chatgpt_response
    file.puts "\nReferências dos URLs utilizados:\n"
    urls_used.each do |url|
      file.puts url
    end
  end

  puts "Insights gerados e salvos em 'chatgpt_insights.txt'"
end

# URL do site da empresa
base_url = ENV['INSTITUTIONAL_COMPANY_BASE_URL'] # Coloque o URL da empresa aqui

puts "Iniciando o processo de scraping..."

# Coleta as informações do site com acompanhamento do progresso
site_data, urls_used = scrape_site(base_url, ['/'], method(:show_progress))

puts "Scraping concluído. Gerando insights com o ChatGPT..."

# Gera insights usando o ChatGPT e salva no arquivo, incluindo URLs usados
generate_insights(site_data, urls_used)

puts "Processo concluído!"