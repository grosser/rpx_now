require 'activesupport'
module RPXNow
  extend self
  def user_data(token,api_key)
    raise "NO API KEY" if api_key.blank?
    data = post('https://rpxnow.com/api/v2/auth_info',{:token=>token,:apiKey=>api_key})
    data = ActiveSupport::JSON.decode(data)
    return if data['err']
    read_user_data_from_response(data)
  end

  def embed_code(subdomain,url)
<<EOF
<iframe src="https://#{subdomain}.rpxnow.com/openid/embed?token_url=#{url}"
  scrolling="no" frameBorder="no" style="width:400px;height:240px;">
</iframe>
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

  def post(url,data)
    require 'net/http'
    url = URI.parse(url)
    http = Net::HTTP.new(url.host, url.port)
    if url.scheme == 'https'
      require 'net/https'
      http.use_ssl = true
    end
    resp, data = http.post(url.path, data.to_query)
    raise "POST FAILED:"+resp.inspect unless resp.is_a? Net::HTTPOK
    return data
  end
end