require_relative 'config/logger_config'
require_relative 'lib/scraper'
require_relative 'lib/analysis_generator'
require_relative 'lib/application'
require 'dotenv/load'

app = Application.new
app.run
