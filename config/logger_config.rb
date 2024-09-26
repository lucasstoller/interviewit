require 'logger'
require_relative 'multi_i_o'

class LoggerConfig
  def self.build_logger
    Dir.mkdir('logs') unless Dir.exist?('logs')

    log_level = ENV['LOG_LEVEL'] || 'INFO' # Default to INFO if LOG_LEVEL is not set
    log_file = File.open('logs/app.log', 'a') # 'a' for append mode

    logger = Logger.new(STDOUT, log_file) # Logs will now be written to 'logs/app.log'

    # Convert the environment log level to a Logger level
    logger.level = case log_level.upcase
                   when 'DEBUG'
                     Logger::DEBUG
                   when 'INFO'
                     Logger::INFO
                   when 'WARN'
                     Logger::WARN
                   when 'ERROR'
                     Logger::ERROR
                   when 'FATAL'
                     Logger::FATAL
                   else
                     Logger::INFO # Fallback to INFO if level is invalid
                   end

    logger
  end
end
