module RPXNow
  class Request
    HOST = 'rpxnow.com'
    SSL_CERT = File.join(File.dirname(__FILE__), '..', '..', 'certs', 'ssl_cert.pem')

    def self.post(path, data)
      parse_response(request(path,data))
    end

    private

    def self.request(path, data)
      request = Net::HTTP::Post.new(path)
      request.form_data = data.map{|k,v| [k.to_s,v]}#symbol keys -> string because of ruby 1.9.x bug http://redmine.ruby-lang.org/issues/show/1351
      make_request(request)
    end

    def self.make_request(request)
      http = Net::HTTP.new(HOST, 443)
      http.use_ssl = true
      http.ca_file = SSL_CERT
      http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      http.verify_depth = 5
      http.request(request)
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