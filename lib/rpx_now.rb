require 'activesupport'
module RPXNow
  extend self

  # retrieve the users data, or return nil when nothing could be read/token was invalid
  def user_data(token,api_key,parameters={})
    begin
      data = secure_json_post('https://rpxnow.com/api/v2/auth_info',{:token=>token,:apiKey=>api_key}.merge(parameters))
    rescue ServerError
      return nil if $!.to_s.to_s =~ /token/ #to_s returns a Hash, WTF?
      raise
    end
    if block_given? then yield(data) else read_user_data_from_response(data) end
  end

  # maps an identifier to an primary-key (e.g. user.id)
  def map(identifier,primary_key,api_key,options={})
    secure_json_post('https://rpxnow.com/api/v2/map',{:identifier=>identifier,:primaryKey=>primary_key,:apiKey=>api_key}.merge(options))
  end

  # un-maps an identifier to an primary-key (e.g. user.id)
  def unmap(identifier,primary_key,api_key)
    secure_json_post('https://rpxnow.com/api/v2/unmap',{:identifier=>identifier,:primaryKey=>primary_key,:apiKey=>api_key})
  end

  # returns an array of identifiers which are mapped to one of your primary-keys (e.g. user.id)
  def mappings(primary_key,api_key)
    data = secure_json_post('https://rpxnow.com/api/v2/mappings',{:primaryKey=>primary_key,:apiKey=>api_key})
    data['identifiers']
  end

  def embed_code(subdomain,url)
<<EOF
<iframe src="https://#{subdomain}.rpxnow.com/openid/embed?token_url=#{url}"
  scrolling="no" frameBorder="no" style="width:400px;height:240px;">
</iframe>
EOF
  end

  def popup_code(text,subdomain,url,options={})
<<EOF
<a class="rpxnow" onclick="return false;" href="https://#{subdomain}.rpxnow.com/openid/v2/signin?token_url=#{url}">
  #{text}
</a>
<script src="https://rpxnow.com/openid/v2/widget" type="text/javascript"></script>
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

private

  def read_user_data_from_response(response)
    user_data = response['profile']
    data = {}
    data[:identifier] = user_data['identifier']
    data[:email] = user_data['verifiedEmail'] || user_data['email']
    data[:name] = user_data['displayName'] || user_data['preferredUsername'] || data[:email].sub(/@.*/,'')
    data
  end

  def secure_json_post(url,data={})
    data = ActiveSupport::JSON.decode(post(url,data))
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
    resp, data = http.post(url.path, data.to_query)
    raise "POST FAILED:"+resp.inspect unless resp.is_a? Net::HTTPOK
    data
  end

  class ServerError < Exception
  end
end