[RPX](http://rpxnow.com) allows users to login to your page through Facebook / Twitter / Myspace / Google / OpenId / MS-LiveId / AOL / ...

 - Simpler then OpenId/OAuth/xxx for developers AND users
 - Publish user activity to facebook/twitter/myspace/.../-stream
 - Returning users are greeted by their provider

![Single Interface for all providers](https://s3.amazonaws.com/static.rpxnow.com/rel/img/a481ed2afccd255350cccd738050f873.png)
![Share comments and activities](https://s3.amazonaws.com/static.rpxnow.com/rel/img/50bdccdb32b6ae68d46908a531492b28.png)
![Visitors choose from providers they already have](https://s3.amazonaws.com/static.rpxnow.com/rel/img/f4a6e65808eefcf8754588c71f84c142.png)

Usage
=====
 - Get an API key @ [RPX](http://rpxnow.com)
 - run [MIGRATION](http://github.com/grosser/rpx_now/raw/master/MIGRATION)
 - Build login view
 - Receive user-data from RPX to create or login User
 - for more advanced features have a look at the [RPX API Docs](https://rpxnow.com/docs)

Install
=======
 - As Rails plugin: `script/plugin install git://github.com/grosser/rpx_now.git `
 - As gem: `sudo gem install rpx_now`

Examples
========

[Example application](http://github.com/grosser/rpx_now_example), go play around!

View
----
    <%=RPXNow.embed_code('My-Rpx-Domain', url_for(:controller=>:session, :action=>:rpx_token, :only_path => false))%>
    OR
    <%=RPXNow.popup_code('Login here...', 'My-Rpx-Domain', url_for(:controller=>:session, :action=>:rpx_token, :only_path => false), options)%>

###Options
`:language=>'en'` rpx tries to detect the users language, but you may overwrite it [possible languages](https://rpxnow.com/docs#sign-in_localization)  
`:default_provider=>'google'` [possible default providers](https://rpxnow.com/docs#sign-in_default_provider)  
`:flags=>'show_provider_list'` [possible flags](https://rpxnow.com/docs#sign-in_interface)  
`:html => {:id => 'xxx'}` is added to the popup link (popup_code only)

###Unobtrusive / JS-last
`popup_code` can also be called with `:unobtrusive=>true` ( --> just link without javascript include).  
To still get the normal popup add `RPXNow.popup_source('My-Rpx-Domain', url_for(:controller=>:session, :action=>:rpx_token, :only_path => false), [options])`.  
Options like :language / :flags should be given for both.

environment.rb
--------------
    Rails::Initializer.run do |config|
      config.gem "rpx_now"
      ...

      config.after_initialize do # so rake gems:install works
        RPXNow.api_key = "YOU RPX API KEY"
      end
    end

Controller
----------
    skip_before_filter :verify_authenticity_token, :only => [:rpx_token] # RPX does not pass Rails form tokens...

    # user_data
    # found: {:name=>'John Doe', :username => 'john', :email=>'john@doe.com', :identifier=>'blug.google.com/openid/dsdfsdfs3f3'}
    # not found: nil (can happen with e.g. invalid tokens)
    def rpx_token
      raise "hackers?" unless data = RPXNow.user_data(params[:token])
      self.current_user = User.find_by_identifier(data[:identifier]) || User.create!(data)
      redirect_to '/'
    end

    # getting additional profile fields (these fields are rarely filled)
    # all possibilities: https://rpxnow.com/docs#profile_data
    data = RPXNow.user_data(params[:token], :additional => [:gender, :birthday, :photo, :providerName, ...])

    # normal + raw data
    RPXNow.user_data(params[:token], :additional => [:raw_response])[:raw_response]['profile]['verifiedEmail']

    # only raw data
    email = RPXNow.user_data(params[:token], :raw_response => true)['profile']['verifiedEmail']

    # with extended info like friends, accessCredentials, portable contacts. (most Providers do not supply them)
    RPXNow.user_data(params[:token], :extended => true)[:extended]['friends'][...have a look at the RPX API DOCS...]

Advanced
--------
### Versions
    RPXNow.api_version = 2

### Mappings (PRX Plus/Pro)
You can map your primary keys (e.g. user.id) to identifiers, so that  
users can login to the same account with multiple identifiers.
    RPXNow.map(identifier, primary_key) #add a mapping
    RPXNow.unmap(identifier, primary_key) #remove a mapping
    RPXNow.mappings(primary_key) # [identifier1,identifier2,...]
    RPXNow.all_mappings # [["1",['google.com/dsdas','yahoo.com/asdas']], ["2",[...]], ... ]

After a primary key is mapped to an identifier, when a user logs in with this identifier,  
`RPXNow.user_data` will contain his `primaryKey` as `:id`.  
A identifyer can only belong to one user (in doubt the last one it was mapped to)

### User integration (e.g. ActiveRecord)
    class User < ActiveRecord::Base
      include RPXNow::UserIntegration
    end

    user.rpx.identifiers == RPXNow.mappings(user.id)
    user.rpx.map(identifier) == RPXNow.map(identifier, user.id)
    user.rpx.unmap(identifier) == RPXNow.unmap(identifier, user.id)

### Contacts (PRX Pro)
Retrieve all contacts for a given user:
    RPXNow.contacts(identifier).each {|c| puts "#{c['displayName']}: #{c['emails']}}

### Status updates (PRX Plus/Pro)
Send a status update to provider (a tweet/facebook-status/...) :
    RPXNow.set_status(identifier, "I just registered at yourdomain.com ...")

### Activity (RPX Plus/Pro)
Post a users activity, on their e.g. Facebook profile, complete with images, titels, rating, additional media, customized links and so on ...
    RPXNow.activity( identifier,
      :url=>href, :action=>'Im loving my new', :user_generated_content=>'Im loving my new ... ',
      :title=>product.title, :description=>product.description,
      :action_links=>[{:text=>'view >>', :href=>product_url(product, :only_path => false)}],
      :media=>[{:type=>:image, :src=>product.image_url, :href=>product_url(product, :only_path => false)}]
    }

### Offline user data access (RPX Plus/Pro)
Same response as auth_info but can be called with a identifier at any time.
Offline Profile Access must be enabled.
    RPXNow.get_user_data(identifier, :extended => true)

### Auth info
Same response as user_data with :raw_response, but without any kind of failure detection or post processing.
    RPXNow.auth_info(params[:token])

Author
======

__[rpx_now_gem mailing list](http://groups.google.com/group/rpx_now_gem)__


###Contributors
 - [Amunds](http://github.com/Amunds)
 - [Bob Groeneveld](http://metathoughtfacility.blogspot.com)
 - [DBA](http://github.com/DBA)
 - [dbalatero](http://github.com/dbalatero)
 - [Paul Gallagher](http://tardate.blogspot.com/)
 - [jackdempsey](http://jackndempsey.blogspot.com)
 - [Patrick Reagan (reagent)](http://sneaq.net)
 - [Joris Trooster (trooster)](http://www.interstroom.nl)
 - [Mick Staugaard (staugaard)](http://mick.staugaard.com/)
 - [Kasper Weibel](http://github.com/weibel)
 - [Nicolas Alpi](http://www.notgeeklycorrect.com)
 - [Ladislav Martincik](http://martincik.com)
 - [Ben Aldred](http://github.com/benaldred)
 - [Casper Fabricius](http://casperfabricius.com)

[Michael Grosser](http://pragmatig.wordpress.com)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...
