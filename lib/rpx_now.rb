require 'json'
require 'rpx_now/contacts_collection'
require 'rpx_now/user_integration'
require 'rpx_now/user_proxy'

module RPXNow
  extend self

  HOST = 'rpxnow.com'
  SSL_CERT = File.join(File.dirname(__FILE__), '..', 'certs', 'ssl_cert.pem')

  attr_accessor :api_key
  attr_accessor :api_version
  self.api_version = 2

  # retrieve the users data, or return nil when nothing could be read/token was invalid
  # or data was not found
  def user_data(token, *args)
    api_key, version, options = extract_key_version_and_options!(args)
    options = {:token=>token,:apiKey=>api_key}.merge options

    begin
      data = secure_json_post("/api/v#{version}/auth_info", options)
    rescue ServerError
      return nil if $!.to_s=~/Data not found/
      raise
    end
    if block_given? then yield(data) else read_user_data_from_response(data) end
  end

  # maps an identifier to an primary-key (e.g. user.id)
  def map(identifier, primary_key, *args)
    api_key, version, options = extract_key_version_and_options!(args)
    options = {:identifier=>identifier,:primaryKey=>primary_key,:apiKey=>api_key}.merge options
    secure_json_post("/api/v#{version}/map", options)
  end

  # un-maps an identifier to an primary-key (e.g. user.id)
  def unmap(identifier, primary_key, *args)
    api_key, version, options = extract_key_version_and_options!(args)
    options = {:identifier=>identifier,:primaryKey=>primary_key,:apiKey=>api_key}.merge options
    secure_json_post("/api/v#{version}/unmap", options)
  end

  # returns an array of identifiers which are mapped to one of your primary-keys (e.g. user.id)
  def mappings(primary_key, *args)
    api_key, version, options = extract_key_version_and_options!(args)
    options = {:primaryKey=>primary_key,:apiKey=>api_key}.merge options
    data = secure_json_post("/api/v#{version}/mappings", options)
    data['identifiers']
  end

  def all_mappings(*args)
    api_key, version, options = extract_key_version_and_options!(args)
    data = secure_json_post("/api/v#{version}/all_mappings", {:apiKey => api_key}.merge(options))
    data['mappings']
  end

  def contacts(identifier, *args)
    api_key, version, options = extract_key_version_and_options!(args)
    options = {:apiKey => api_key, :identifier=> identifier}.merge(options)
    data = secure_json_post("/api/v#{version}/get_contacts", options)
    RPXNow::ContactsCollection.new(data['response'])
  end
  alias get_contacts contacts

  def embed_code(subdomain,url)
<<EOF
<iframe src="https://#{subdomain}.#{HOST}/openid/embed?token_url=#{url}"
  scrolling="no" frameBorder="no" style="width:400px;height:240px;">
</iframe>
EOF
  end

  def popup_code(text, subdomain, url, options = {})
    if options[:unobtrusive]
      unobtrusive_popup_code(text, subdomain, url, options)
    else
      obtrusive_popup_code(text, subdomain, url, options)
    end
  end

  private

  def unobtrusive_popup_code(text, subdomain, url, options={})
    version = extract_version! options
    "<a class=\"rpxnow\" href=\"https://#{subdomain}.#{HOST}/openid/v#{version}/signin?token_url=#{url}\">#{text}</a>"
  end

  def obtrusive_popup_code(text, subdomain, url, options = {})
    version = extract_version! options
    <<EOF
<a class="rpxnow" onclick="return false;" href="https://#{subdomain}.#{HOST}/openid/v#{version}/signin?token_url=#{url}">
  #{text}
</a>
<script src="https://#{HOST}/openid/v#{version}/widget" type="text/javascript"></script>
<script type="text/javascript">
  //<![CDATA[
  RPXNOW.token_url = "#{url}";

  RPXNOW.realm = "#{subdomain}";
  RPXNOW.overlay = true;
  RPXNOW.language_preference = '#{options[:language]||'en'}';
  //]]>
</script>
EOF
  end

  def extract_key_version_and_options!(args)
    key, options = extract_key_and_options(args)
    version = extract_version! options
    [key, version, options]
  end

  # [API_KEY,{options}] or
  # [{options}] or
  # []
  def extract_key_and_options(args)
    if args.length == 2
      [args[0],args[1]]
    elsif args.length==1
      if args[0].is_a? Hash then [@api_key,args[0]] else [args[0],{}] end
    else
      raise "NO Api Key found!" unless @api_key
      [@api_key,{}]
    end
  end

  def extract_version!(options)
    options.delete(:api_version) || api_version
  end

  def read_user_data_from_response(response)
    user_data = response['profile']
    data = {}
    data[:identifier] = user_data['identifier']
    data[:email] = user_data['verifiedEmail'] || user_data['email']
    data[:username] = user_data['preferredUsername'] || data[:email].to_s.sub(/@.*/,'')
    data[:name] = user_data['displayName'] || data[:username]
    data[:id] = user_data['primaryKey'] unless user_data['primaryKey'].to_s.empty?
    data
  end

  def secure_json_post(path, data)
    parse_response(post(path,data))
  end

  def post(path, data)
    require 'net/http'
    require 'net/https'
    request = Net::HTTP::Get.new(path)
    request.form_data = data.map{|k,v| [k.to_s,v]}#symbol keys -> string because of ruby 1.9.x bug http://redmine.ruby-lang.org/issues/show/1351
    make_request(request)
  end

  def make_request(request)
    http = Net::HTTP.new(HOST, 443)
    http.use_ssl = true
    http.ca_file = SSL_CERT
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.verify_depth = 5
    http.request(request)
  end

  def parse_response(response)
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

  class ServerError < Exception; end #backwards compatibility / catch all
  class ApiError < ServerError; end
  class ServiceUnavailableError < ServerError; end
end
