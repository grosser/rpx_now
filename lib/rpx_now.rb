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
    begin
      data = Api.call("auth_info", options.merge(:token => token))
      if block_given? then yield(data) else parse_user_data(data, options) end
    rescue ServerError
      return nil if $!.to_s=~/Data not found/
      raise
    end
  end

  # set the users status
  def set_status(identifier, status, options={})
    options = options.merge(:identifier => identifier, :status => status)
    data = Api.call("set_status", options)
  rescue ServerError
    return nil if $!.to_s=~/Data not found/
    raise
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

  # iframe for rpx login
  # options: :width, :height, :language, :flags
  def embed_code(subdomain, url, options={})
    options = {:width => '400', :height => '240'}.merge(options)
    <<-EOF
      <iframe src="#{Api.host(subdomain)}/openid/embed?#{embed_params(url, options)}"
        scrolling="no" frameBorder="no" style="width:#{options[:width]}px;height:#{options[:height]}px;">
      </iframe>
    EOF
  end

  # popup window for rpx login
  # options: :language / :flags / :unobtrusive
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
    (options[:additional] || []).each do |key|
      data[key] = user_data[key.to_s]
    end
    data
  end

  def unobtrusive_popup_code(text, subdomain, url, options={})
    %Q(<a class="rpxnow" href="#{Api.host(subdomain)}/openid/v#{extract_version(options)}/signin?#{embed_params(url, options)}">#{text}</a>)
  end

  def obtrusive_popup_code(text, subdomain, url, options = {})
    unobtrusive_popup_code(text, subdomain, url, options) +
    popup_source(subdomain, url, options)
  end

  class ServerError < RuntimeError; end #backwards compatibility / catch all
  class ApiError < ServerError; end
  class ServiceUnavailableError < ServerError; end
end
