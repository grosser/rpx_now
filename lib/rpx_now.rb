require 'json'

module RPXNow
  extend self

  attr_writer :api_key
  attr_accessor :api_version
  self.api_version = 2

  # retrieve the users data, or return nil when nothing could be read/token was invalid
  # or data was not found
  def user_data(token, *args)
    api_key, version, options = extract_key_version_and_options!(args)
    options = {:token=>token,:apiKey=>api_key}.merge options

    begin
      data = secure_json_post("https://rpxnow.com/api/v#{version}/auth_info", options)
    rescue ServerError
      return nil if $!.to_s =~ /token/ or $!.to_s=~/Data not found/
      raise
    end
    if block_given? then yield(data) else read_user_data_from_response(data) end
  end

  # maps an identifier to an primary-key (e.g. user.id)
  def map(identifier, primary_key, *args)
    api_key, version, options = extract_key_version_and_options!(args)
    options = {:identifier=>identifier,:primaryKey=>primary_key,:apiKey=>api_key}.merge options
    secure_json_post("https://rpxnow.com/api/v#{version}/map", options)
  end

  # un-maps an identifier to an primary-key (e.g. user.id)
  def unmap(identifier, primary_key, *args)
    api_key, version, options = extract_key_version_and_options!(args)
    options = {:identifier=>identifier,:primaryKey=>primary_key,:apiKey=>api_key}.merge options
    secure_json_post("https://rpxnow.com/api/v#{version}/unmap", options)
  end

  # returns an array of identifiers which are mapped to one of your primary-keys (e.g. user.id)
  def mappings(primary_key, *args)
    api_key, version, options = extract_key_version_and_options!(args)
    options = {:primaryKey=>primary_key,:apiKey=>api_key}.merge options
    data = secure_json_post("https://rpxnow.com/api/v#{version}/mappings", options)
    data['identifiers']
  end

  def embed_code(subdomain,url)
<<EOF
<iframe src="https://#{subdomain}.rpxnow.com/openid/embed?token_url=#{url}"
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
    "<a class=\"rpxnow\" href=\"https://#{subdomain}.rpxnow.com/openid/v#{version}/signin?token_url=#{url}\">#{text}</a>"
  end

  def obtrusive_popup_code(text, subdomain, url, options = {})
    version = extract_version! options
    <<EOF
<a class="rpxnow" onclick="return false;" href="https://#{subdomain}.rpxnow.com/openid/v#{version}/signin?token_url=#{url}">
  #{text}
</a>
<script src="https://rpxnow.com/openid/v#{version}/widget" type="text/javascript"></script>
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
      raise unless @api_key
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
    data[:username] = user_data['preferredUsername'] || data[:email].sub(/@.*/,'')
    data[:name] = user_data['displayName'] || data[:username]
    data[:id] = user_data['primaryKey'] unless user_data['primaryKey'].to_s.empty?
    data
  end

  def secure_json_post(url,data={})
    data = JSON.parse(post(url,data))
    raise ServerError.new(data['err']) if data['err']
    raise ServerError.new(data.inspect) unless data['stat']=='ok'
    data
  end

  def post(url,data)
    require 'net/http'
    url = URI.parse(url)
    http = Net::HTTP.new(url.host, url.port)
    if url.scheme == 'https'
      require 'net/https'
      http.use_ssl = true
      #TODO do we really want to verify the certificate? http://notetoself.vrensk.com/2008/09/verified-https-in-ruby/
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    resp, data = http.post(url.path, to_query(data))
    raise "POST FAILED:"+resp.inspect unless resp.is_a? Net::HTTPOK
    data
  end

  def to_query(data = {})
    return data.to_query if Hash.respond_to? :to_query
    return "" if data.empty?

    #simpler to_query
    query_data = []
    data.each do |k, v|
      query_data << "#{k}=#{v}"
    end
    
    return query_data.join('&')
  end

  class ServerError < Exception
    #to_s returns message(which is a hash...)
    def to_s
      super.to_s
    end
  end
end
