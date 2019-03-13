# frozen_string_literal: true

module Middleware
  class Logger < Grape::Middleware::Base
    include ANSIColor
    include ErrorHandling

    SLASH = '/'

    GRAPE_PARAMS = Grape::Env::GRAPE_REQUEST_PARAMS
    RACK_REQUEST_BODY = Grape::Env::RACK_REQUEST_FORM_HASH
    ACTION_DISPATCH_PARAMS = 'action_dispatch.request.request_parameters'

    attr_reader :logger

    def initialize(app, headers: nil, **options)
      @app = app

      @options = options
      @logger = Rails.application.config.logger
      @filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      @display_headers = headers
    end

    def call!(env)
      @env = env

      if logger.respond_to?(:tagged)
        request_id = RequestStore.store[:request_id]
        logger.tagged(black(request_id)) { perform }
      else
        perform
      end
    end

    private

    def perform
      start_timings
      log_request

      response = call_with_error_handling do |error|
        log_failure(error)
      end

      response.tap do |(status, _headers, _body)|
        log_response(status)
      end
    rescue StandardError => e
      log_error(e)
      raise e
    end

    def log_request
      request = env[Grape::Env::GRAPE_REQUEST]
      method = request.request_method

      logger.info ''
      logger.info format('%<method>s %<path>s -> %<processor>s', method: white(method, bold: true),
                                                                 path: white(request.path),
                                                                 processor: cyan(processed_by, bold: true))
      logger.info "  Parameters: #{magenta(parameters)}"
      logger.info "  Headers: #{magenta(filtered_headers)}" if @display_headers
    end

    def log_response(status)
      logger.info green("Completed #{status} in #{total_runtime}ms")
      logger.info ''
    end

    def log_failure(error)
      message = error[:message]&.fetch(:message, error[:message].to_s)
      message ||= '<NO RESPONSE>'

      logger.warn yellow("  ! Failing with #{error[:status]} (#{message})", bold: true)

      error[:headers] ||= {}
      log_response(error[:status])
    end

    def log_error(error)
      logger.error red("UNCAUGHT EXCEPTION: (#{error.message})", bold: true)
      logger.error red(error.backtrace.inspect)
      logger.info ''
    end

    def parameters
      request_params = env[GRAPE_PARAMS].to_hash
      request_params.merge!(env[RACK_REQUEST_BODY]) if env[RACK_REQUEST_BODY]
      request_params.merge!(env[ACTION_DISPATCH_PARAMS]) if env[ACTION_DISPATCH_PARAMS]

      @filter.filter(request_params)
    end

    def filtered_headers
      return request_headers if @display_headers == :all

      Array(@display_headers).each_with_object({}) do |name, acc|
        normalized_name = name.titlecase.tr(' ', '-') # X-Sample-header-NAME => X-Sample-Header-Name
        header_value = request_headers.fetch(normalized_name, nil)

        acc[normalized_name] = header_value if header_value
      end
    end

    def request_headers
      @request_headers ||= env[Grape::Env::GRAPE_REQUEST_HEADERS].to_hash
    end

    def start_timings
      @runtime_start = Time.now
      @total_runtime = nil
    end

    def total_runtime
      @total_runtime ||= ((Time.now - @runtime_start) * 1_000).round(2)
    end

    def processed_by
      endpoint = env[Grape::Env::API_ENDPOINT]

      result = []
      result << (endpoint.namespace == SLASH ? '' : endpoint.namespace)

      result.concat(endpoint.options[:path].map { |path| path.to_s.sub(SLASH, '') })
      endpoint.options[:for].to_s << result.join(SLASH)
    end
  end
end
