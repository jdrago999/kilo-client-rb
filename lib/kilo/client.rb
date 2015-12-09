
require 'active_support/core_ext/object'
require 'active_support/json'
require 'httparty'

module Kilo
  class AuthError < StandardError; end
  class NotYetAuthenticatedError < StandardError; end
  class PublishError < StandardError; end
  class Client
    include HTTParty
    attr_accessor :username, :vhost, :hostname, :cookies, :authenticated, :debug
    def initialize(args={})
      args.except(:password).each do |key,val|
        self.send("#{key}=", val)
      end
      @password = args[:password]
      self.class.base_uri "https://#{self.hostname}"
      self.cookies = [ ]
      self.authenticated = false
    end

    def debug=(value)
      @debug = value
      if value
        self.class.debug_output
      else
        self.class.debug_output false
      end
    end

    def authenticate!
      response = self.class.post('/api/auth',
        verify: false,
        body: {
          username: self.username,
          password: @password
        }
      )
      if response.code.to_i == 200
        self.cookies = [ parse_cookie(response).to_cookie_string ]
        self.authenticated = true
      else
        raise AuthError.new "Cannot authenticate as '#{self.username}' on host '#{self.hostname}'"
      end
    end

    def authenticated?
      @authenticated
    end

    def publish(channel, messages=[], options={})
      unless self.authenticated?
        raise NotYetAuthenticatedError.new "You must first call authenticate! before publishing messages."
      end
      response = self.class.post("/api/#{self.vhost}/channels/#{channel}/publish",
        verify: false,
        headers: {'Cookie' => self.cookies.join('; ')},
        body: {
          messages: ( messages.is_a?(Array) ? messages : [messages] ),
        }.merge(options.slice(:autocreate))
      )
      case response.code
      when 200
        OpenStruct.new( JSON.parse(response.body, symbolize_names: true) )
      when 401
        raise AuthError.new response.body
      else
        raise PublishError.new response.body
      end
    end

    private

    def parse_cookie(resp)
      cookie_hash = CookieHash.new
      resp.get_fields('Set-Cookie').each { |c| cookie_hash.add_cookies(c) }
      cookie_hash
    end
  end
end
