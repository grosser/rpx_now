require 'net/http'
require 'net/https'
require 'json'

require 'rpx_now/request'
require 'rpx_now/contacts_collection'
require 'rpx_now/user_integration'
require 'rpx_now/user_proxy'

module RPXNow
  extend self

  attr_accessor :api_key
  attr_accessor :api_version
  self.api_version = 2

  # retrieve the users data
  # - cleaned Hash
  # - complete/unclean response when block was given user_data{|response| ...; return hash }
  # - nil when token was invalid / data was not found
  def user_data(token, *args)
    api_key, version, options = extract_key_version_and_options!(args)
    options = {:token=>token,:apiKey=>api_key}.merge options

    begin
      data = secure_json_post("/api/v#{version}/auth_info", options)
    rescue ServerError
      return nil if $!.to_s=~/Data not found/
      raise
    end
    if block_given? then yield(data) else parse_user_data(data) end
  end

  # set the users status
  def set_status(identifier, status, *args)
    api_key, version, options = extract_key_version_and_options!(args)
    options = {:identifier => identifier, :status => status, :apiKey => api_key}.merge options

    begin
      data = secure_json_post("/api/v#{version}/set_status", options)
    rescue ServerError
      return nil if $!.to_s=~/Data not found/
      raise
    end
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

  def embed_code(subdomain,url,options={})
    options = {:width => '400', :height => '240', :language => 'en'}.merge(options)
<<EOF
<iframe src="https://#{subdomain}.#{Request::HOST}/openid/embed?token_url=#{url}&language_preference=#{options[:language]}"
  scrolling="no" frameBorder="no" style="width:#{options[:width]}px;height:#{options[:height]}px;">
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

  def self.parse_user_data(response)
    user_data = response['profile']
    data = {}
    data[:identifier] = user_data['identifier']
    data[:email] = user_data['verifiedEmail'] || user_data['email']
    data[:username] = user_data['preferredUsername'] || data[:email].to_s.sub(/@.*/,'')
    data[:name] = user_data['displayName'] || data[:username]
    data[:id] = user_data['primaryKey'] unless user_data['primaryKey'].to_s.empty?
    data
  end

  def unobtrusive_popup_code(text, subdomain, url, options={})
    version = extract_version! options
    "<a class=\"rpxnow\" href=\"https://#{subdomain}.#{Request::HOST}/openid/v#{version}/signin?token_url=#{url}\">#{text}</a>"
  end

  def obtrusive_popup_code(text, subdomain, url, options = {})
    version = extract_version! options
    <<EOF
<a class="rpxnow" onclick="return false;" href="https://#{subdomain}.#{Request::HOST}/openid/v#{version}/signin?token_url=#{url}">
  #{text}
</a>
<script src="https://#{Request::HOST}/openid/v#{version}/widget" type="text/javascript"></script>
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

  def secure_json_post(path, data)
    Request.post(path, data)
  end

  class ServerError < RuntimeError; end #backwards compatibility / catch all
  class ApiError < ServerError; end
  class ServiceUnavailableError < ServerError; end
end
