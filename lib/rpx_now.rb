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

  VERSION = File.read( File.join(File.dirname(__FILE__),'..','VERSION') ).strip

  # retrieve the users data
  # - cleaned Hash
  # - complete/unclean response when block was given user_data{|response| ...; return hash }
  # - nil when token was invalid / data was not found
  def user_data(token, options={})
    begin
      data = Request.post("auth_info", options.merge(:token => token))
      if block_given? then yield(data) else parse_user_data(data) end
    rescue ServerError
      return nil if $!.to_s=~/Data not found/
      raise
    end
  end

  # set the users status
  def set_status(identifier, status, options={})
    options = options.merge(:identifier => identifier, :status => status)
    data = Request.post("set_status", options)
  rescue ServerError
    return nil if $!.to_s=~/Data not found/
    raise
  end

  # maps an identifier to an primary-key (e.g. user.id)
  def map(identifier, primary_key, options={})
    Request.post("map", options.merge(:identifier => identifier, :primaryKey => primary_key))
  end

  # un-maps an identifier to an primary-key (e.g. user.id)
  def unmap(identifier, primary_key, options={})
    Request.post("unmap", options.merge(:identifier => identifier, :primaryKey => primary_key))
  end

  # returns an array of identifiers which are mapped to one of your primary-keys (e.g. user.id)
  def mappings(primary_key, options={})
    Request.post("mappings", options.merge(:primaryKey => primary_key))['identifiers']
  end

  def all_mappings(options={})
    Request.post("all_mappings", options)['mappings']
  end

  def contacts(identifier, options={})
    data = Request.post("get_contacts", options.merge(:identifier => identifier))
    RPXNow::ContactsCollection.new(data['response'])
  end
  alias get_contacts contacts

  def embed_code(subdomain,url,options={})
    options = {:width => '400', :height => '240', :language => 'en'}.merge(options)
    <<-EOF
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

  def extract_version!(options)
    options.delete(:api_version) || api_version
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
    <<-EOF
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

  class ServerError < RuntimeError; end #backwards compatibility / catch all
  class ApiError < ServerError; end
  class ServiceUnavailableError < ServerError; end
end
