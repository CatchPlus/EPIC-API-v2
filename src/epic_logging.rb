require 'logger'
require 'forwardable'
require 'singleton'

module EPIC
  # Logging Singleton for EPIC
  class Logging

    include Singleton
    
    extend Forwardable

    def initialize
      # Set Filepath
      @logger = Logger.new(
        LOG_SETTINGS[:log_path],
        LOG_SETTINGS[:max_log_days], 
        LOG_SETTINGS[:max_log_mb] * 1024 * 1024)
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
      size = LOG_SETTINGS[:max_log_mb] > 0 ? "#{LOG_SETTINGS[:max_log_mb]} Megabyte" : "unlimited" 
      self.info("Log-Settings - retention: #{duration} - Maximum size #{size}.")
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

    def info_httpevent(message="", request_type="GET")
      request = Rackful::Request.current
      if request && request.env['REQUEST_METHOD'] == request_type.upcase
        env = request.env
        query_string = "with query: #{env['QUERY_STRING']}" if env['QUERY_STRING'].size > 1
        info_message =
          "#{env['REQUEST_METHOD']} from #{env['REMOTE_USER']}@#{env['REMOTE_ADDR']} " +
          "on #{env['PATH_INFO']} #{query_string}Return format: #{env['HTTP_ACCEPT']}: >> #{message}."
        self.info(info_message)
      end
    end
    
    def_delegators :@logger, :info, :error, :fatal, :warn, :debug

  end
end
