require 'faraday'
require 'oj'
require 'logger'
require 'awesome_print' # for debug output

require './toggl_reports_getters'

# :mode => :compat will convert symbols to strings
Oj.default_options = { :mode => :compat }

module TogglReports
  TOGGL_REPORTS_API_URL = 'https://www.toggl.com/reports/api/v2'
  DELAY_SEC = 1
  MAX_RETRIES = 3

  class API
    API_TOKEN = 'api_token'
    TOGGL_FILE = '.toggl'

    attr_reader :conn

    def initialize(username=nil, password=API_TOKEN, opts={})
      @logger = Logger.new(STDOUT)
      @logger.level = Logger::WARN

      if username.nil? && password == API_TOKEN
        toggl_api_file = File.join(Dir.home, TOGGL_FILE)
        if FileTest.exist?(toggl_api_file) then
          username = IO.read(toggl_api_file)
        else
          raise "Expecting\n" +
            " 1) api_token in file #{toggl_api_file}, or\n" +
            " 2) parameter: (api_token), or\n" +
            " 3) parameters: (username, password).\n" +
            "\n\tSee https://github.com/toggl/toggl_api_docs/blob/master/chapters/authentication.md"
        end
      end

      @conn = TogglReports::API.connection(username, password, opts)
      @conn.headers[:user_agent] = 'trellogl'
      @conn
    end

    def debug(debug=true)
      if debug
        @logger.level = Logger::DEBUG
      else
        @logger.level = Logger::WARN
      end
    end

  #---------#
  # Private #
  #---------#

  private

    attr_writer :conn

    def self.connection(username, password, opts={})
      Faraday.new(:url => TOGGL_REPORTS_API_URL, :ssl => {:verify => true}) do |faraday|
        faraday.request :url_encoded
        faraday.response :logger, Logger.new('faraday.log') if opts[:log]
        faraday.adapter Faraday.default_adapter
        faraday.headers = { "Content-Type" => "application/json" }
        faraday.basic_auth username, password
      end
    end

    def requireParams(params, fields=[])
      raise ArgumentError, 'params is not a Hash' unless params.is_a? Hash
      return if fields.empty?
      errors = []
      for f in fields
        errors.push("params[#{f}] is required") unless params.has_key?(f)
      end
      raise ArgumentError, errors.join(', ') if !errors.empty?
    end

    def _call_api(procs)
      @logger.debug(procs[:debug_output].call)
      full_resp = nil
      i = 0
      loop do
        i += 1
        full_resp = procs[:api_call].call
        @logger.ap(full_resp.env, :debug)
        break if full_resp.status != 429 || i >= MAX_RETRIES
        sleep(DELAY_SEC)
      end

      raise "HTTP Status: #{full_resp.status}" unless full_resp.success?
      return {} if full_resp.body.nil? || full_resp.body == 'null'

      full_resp
    end

    def get(resource, params={})
      resource.gsub!('+', '%2B')
      full_resp = _call_api(debug_output: lambda { "GET #{resource} / #{params}" },
                            api_call: lambda { self.conn.get(resource, params) } )
      return {} if full_resp == {}
      resp = Oj.load(full_resp.body)
      return resp['data'] if resp.respond_to?(:has_key?) && resp.has_key?('data')
      resp
    end

  end
end
