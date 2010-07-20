require 'rpx_now/api'
require 'rpx_now/contacts_collection'
require 'cgi'

module RPXNow
  extend self

  attr_accessor :api_key
  attr_accessor :api_version
  self.api_version = 2

  VERSION = File.read( File.join(File.dirname(__FILE__),'..','VERSION') ).strip

  # retrieve the users data
  # - cleaned Hash
  # - complete/unclean response when block was given user_data{|response| ...; return hash }
  # - nil when token was invalid / data was not found
  def user_data(token, options={})
    options = options.dup
    return_raw = options.delete(:raw_response)

    data = begin
      auth_info(token, options)
    rescue ServerError
      return nil if $!.to_s=~/Data not found/
      raise
    end

    result = (block_given? ? yield(data) : (return_raw ? data : parse_user_data(data, options)))
    with_indifferent_access(result)
  end

  # same data as user_data, but without any kind of post-processing
  def auth_info(token, options={})
    data = Api.call("auth_info", options.merge(:token => token))
    with_indifferent_access(data)
  end

  # same as for auth_info if Offline Profile Access is enabled,
  # but can be called at any time and does not need a token / does not expire
  def get_user_data(identifier, options={})
    data = Api.call("get_user_data", options.merge(:identifier => identifier))
    with_indifferent_access(data)
  end

  # set the users status
  def set_status(identifier, status, options={})
    options = options.merge(:identifier => identifier, :status => status)
    Api.call("set_status", options)
  rescue ServerError
    return nil if $!.to_s=~/Data not found/
    raise
  end

  # Post an activity update to the user's activity stream.
  # See more: https://rpxnow.com/docs#api_activity
  def activity(identifier, activity_options, options={})
    options = options.merge(:identifier => identifier, :activity => activity_options.to_json)
    Api.call("activity", options)
  end

  # maps an identifier to an primary-key (e.g. user.id)
  def map(identifier, primary_key, options={})
    Api.call("map", options.merge(:identifier => identifier, :primaryKey => primary_key))
  end

  # un-maps an identifier to an primary-key (e.g. user.id)
  def unmap(identifier, primary_key, options={})
    Api.call("unmap", options.merge(:identifier => identifier, :primaryKey => primary_key))
  end

  # returns an array of identifiers which are mapped to one of your primary-keys (e.g. user.id)
  def mappings(primary_key, options={})
    Api.call("mappings", options.merge(:primaryKey => primary_key))['identifiers']
  end

  def all_mappings(options={})
    Api.call("all_mappings", options)['mappings']
  end

  def contacts(identifier, options={})
    data = Api.call("get_contacts", options.merge(:identifier => identifier))
    RPXNow::ContactsCollection.new(data['response'])
  end
  alias get_contacts contacts

  # embedded rpx login (via iframe)
  # options: :width, :height, :language, :flags, :api_version, :default_provider
  def embed_code(subdomain, url, options={})
    options = {:width => '400', :height => '240'}.merge(options)
    <<-EOF
      <iframe src="#{Api.host(subdomain)}/openid/embed?#{embed_params(url, options)}"
        scrolling="no" frameBorder="no" style="width:#{options[:width]}px;height:#{options[:height]}px;" id="rpx_now_embed" allowtransparency="allowtransparency">
      </iframe>
    EOF
  end

  # popup window for rpx login
  # options: :language, :flags, :unobtrusive, :api_version, :default_provider, :html
  def popup_code(text, subdomain, url, options = {})
    if options[:unobtrusive]
      unobtrusive_popup_code(text, subdomain, url, options)
    else
      obtrusive_popup_code(text, subdomain, url, options)
    end
  end

  # javascript for popup
  # only needed in combination with popup_code(x,y,z, :unobtrusive => true)
  def popup_source(subdomain, url, options={})
    <<-EOF
      <script src="#{Api.host}/openid/v#{extract_version(options)}/widget" type="text/javascript"></script>
      <script type="text/javascript">
        //<![CDATA[
        RPXNOW.token_url = '#{url}';
        RPXNOW.realm = '#{subdomain}';
        RPXNOW.overlay = true;
        #{ "RPXNOW.language_preference = '#{options[:language]}';" if options[:language] }
        #{ "RPXNOW.default_provider = '#{options[:default_provider]}';" if options[:default_provider] }
        #{ "RPXNOW.flags = '#{options[:flags]}';" if options[:flags] }
        //]]>
      </script>
    EOF
  end

  # url for unobtrusive popup window
  # options: :language, :flags, :api_version, :default_provider
  def popup_url(subdomain, url, options={})
    "#{Api.host(subdomain)}/openid/v#{extract_version(options)}/signin?#{embed_params(url, options)}"
  end

  def extract_version(options)
    options[:api_version] || api_version
  end

  private

  def self.embed_params(url, options)
    {
      :token_url => CGI::escape( url ),
      :language_preference => options[:language],
      :flags => options[:flags],
      :default_provider => options[:default_provider]
    }.map{|k,v| "#{k}=#{v}" if v}.compact.join('&amp;')
  end

  def self.parse_user_data(response, options)
    user_data = response['profile']
    data = {}
    data[:identifier] = user_data['identifier']
    data[:email] = user_data['verifiedEmail'] || user_data['email']
    data[:username] = user_data['preferredUsername'] || data[:email].to_s.sub(/@.*/,'')
    data[:name] = user_data['displayName'] || data[:username]
    data[:id] = user_data['primaryKey'] unless user_data['primaryKey'].to_s.empty?

    additional = (options[:additional] || [])
    additional << :extended if options[:extended]
    additional.each do |key|
      data[key] = case key
      when :raw
        warn "RPXNow :raw is deprecated, please use :raw_response + e.g. data['raw_response']['profile']['verifiedEmail']"
        user_data
      when :raw_response
        response
      when :extended
        response.reject{|k,v| ['profile','stat'].include?(k) }
      else
        user_data[key.to_s]
      end
    end
    data
  end

  def unobtrusive_popup_code(text, subdomain, url, options={})
    options = options.dup
    html_options = options.delete(:html) || {}
    html_options[:class] = "rpxnow #{html_options[:class]}".strip
    html_options[:href] ||= popup_url(subdomain, url, options)
    html_options = html_options.sort_by{|k,v|k.to_s}.map{|k,v| %{#{k}="#{v}"}}

    %{<a #{html_options.join(' ')}>#{text}</a>}
  end

  def obtrusive_popup_code(text, subdomain, url, options = {})
    unobtrusive_popup_code(text, subdomain, url, options) +
    popup_source(subdomain, url, options)
  end

  def with_indifferent_access(hash)
    hash.respond_to?(:with_indifferent_access) ? hash.with_indifferent_access : hash
  end

  class ServerError < RuntimeError; end #backwards compatibility / catch all
  class ApiError < ServerError; end
  class ServiceUnavailableError < ServerError; end
end