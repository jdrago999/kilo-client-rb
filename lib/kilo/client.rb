
require 'active_support/core_ext/object'
require 'httparty'

module Kilo
  class AuthError < StandardError; end
  class Client
    include HTTParty
    attr_accessor :username, :vhost, :hostname, :cookies, :authenticated
    def initialize(args={})
      args.except(:password).each do |key,val|
        self.send("#{key}=", val)
      end
      @password = args[:password]
      self.class.base_uri "https://#{self.hostname}"
      self.cookies = [ ]
      self.authenticated = false
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

    def parse_cookie(resp)
      cookie_hash = CookieHash.new
      resp.get_fields('Set-Cookie').each { |c| cookie_hash.add_cookies(c) }
      cookie_hash
    end
  end
end
