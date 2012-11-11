require 'logger'
require 'singleton'

module EPIC
  # Logging Class for EPIC
  # Works as Singelton
  class Logging

    # Initialize Singleton
    include Singleton

    private
    @logger
    @env
    @username

    public
    def initialize
      # Set Filepath
      @logger = Logger.new(LOG_SETTINGS[:log_path], LOG_SETTINGS[:max_log_days],  LOG_SETTINGS[:max_log_size] * 1024 * 1024)
      # Terminate Log-Level from config and configure the Logger
      loglevel = case LOG_SETTINGS[:log_level].to_s().upcase
      when 'DEBUG' then Logger::DEBUG
      when 'ERROR' then Logger::ERROR
      when 'FATAL' then Logger::FATAL
      when 'INFO' then Logger::INFO
      when 'WARN' then Logger::WARN
      end
      @logger.level = loglevel
      duration = LOG_SETTINGS[:max_log_days] > 0 ? "#{LOG_SETTINGS[:max_log_days]} days" : "unlimited"
      size = LOG_SETTINGS[:max_log_size] > 0 ? "#{LOG_SETTINGS[:max_log_size]} Megabyte" : "unlimited" 
      self.info("Log-Settings - retention: #{duration} - Maximum size #{size}.")
    end

    def debug(message)
      @logger.debug(message)
    end

    def debug_method(class_reference, caller_reference, args = "")
      classname = class_reference.class.name

      # Findout the name of the method by adding method at runtime
      if @logger.level == Logger::DEBUG and !class_reference.respond_to?(:this_method)
        def class_reference.this_method
          caller[1] =~ /`([^']*)'/ and $1
        end
        methodname = class_reference.this_method
      end

      # Hand Over data to logging.
      self.debug("Calling: #{classname}.'#{methodname} with args: #{args} - by: #{caller_reference.first().split('/').last()}")
    end

    def set_rack_environment(env)
      @env = env
    end

    def set_rack_username(username)
      @username = username
    end

    def info_httpevent(message="", request_type="GET")
      if request_type.upcase == @env['REQUEST_METHOD']
        query_string = "with query: #{@env['QUERY_STRING']}" if @env['QUERY_STRING'].size() > 1
        info_message = \
        "#{@env['REQUEST_METHOD']} from #{@env['REMOTE_ADDR']} - #{@username} " + \
        "on #{@env['PATH_INFO']} #{query_string}Return format: #{@env['HTTP_ACCEPT']}: >> #{message}."
        self.info(info_message)
      end
    end

    def info(message)
      @logger.info(message)
    end

    def error(message)
      @logger.error(message)
    end

    def fatal(message)
      @logger.fatal(message)
    end

    def warn(message)
      @logger.warn(message)
    end

  end
end