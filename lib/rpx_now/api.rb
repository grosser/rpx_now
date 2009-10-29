require 'net/http'
require 'net/https'
require 'json'

module RPXNow
  # low-level interaction with rpxnow.com api
  # - send requests
  # - parse response
  # - handle server errors
  class Api
    HOST = 'rpxnow.com'
    SSL_CERT = File.join(File.dirname(__FILE__), '..', '..', 'certs', 'ssl_cert.pem')

    def self.call(method, data)
      data = data.dup
      version = RPXNow.extract_version(data)
      data.delete(:api_version)

      path = "/api/v#{version}/#{method}"
      response = request(path, {:apiKey => RPXNow.api_key}.merge(data))
      parse_response(response)
    end

    def self.host(subdomain=nil)
      if subdomain
        "https://#{subdomain}.#{Api::HOST}"
      else
        "https://#{Api::HOST}"
      end
    end

    private

    def self.request(path, data)
      client.request(request_object(path, data))
    end

    def self.request_object(path, data)
      request = Net::HTTP::Post.new(path)
      request.form_data = stringify_keys(data)
      request
    end

    # symbol keys -> string keys
    # because of ruby 1.9.x bug in Net::HTTP
    # http://redmine.ruby-lang.org/issues/show/1351
    def self.stringify_keys(hash)
      hash.map{|k,v| [k.to_s,v]}
    end

    def self.client
      client = Net::HTTP.new(HOST, 443)
      client.use_ssl = true
      client.ca_file = SSL_CERT
      client.verify_mode = OpenSSL::SSL::VERIFY_PEER
      client.verify_depth = 5
      client
    end

    def self.parse_response(response)
      if response.code.to_i >= 400
        raise ServiceUnavailableError, "The RPX service is temporarily unavailable. (4XX)"
      else
        result = JSON.parse(response.body)
        return result unless result['err']

        code = result['err']['code']
        if code == -1
          raise ServiceUnavailableError, "The RPX service is temporarily unavailable."
        else
          raise ApiError, "Got error: #{result['err']['msg']} (code: #{code}), HTTP status: #{response.code}"
        end
      end
    end
  end
end