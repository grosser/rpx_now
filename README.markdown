Problem
=======
 - OpenID is complex, limited and hard to use for users
 - Facebook / Twitter / Myspace / Google / MS-LiveId / AOL connections require different libraries and knowledge
 - Multiple heterogenouse providers are hard to map to a single user

Solution
========
 - Use [RPX](http://rpxnow.com) for universal and usable user login
 - Use view/controller helpers for easy integration

![Single Interface for all providers](https://rpxnow.com/images/how_diagram.png)
![Visitors choose from providers they already have](https://rpxnow.com/images/6providers.png?2)

Usage
=====
 - Get an API key @ [RPX](http://rpxnow.com)
 - run [MIGRATION](http://github.com/grosser/rpx_now/raw/master/MIGRATION)
 - Build login view
 - Communicate with RPX API in controller to create or login User
 - for more advanced features have a look at the [RPX API Docs](https://rpxnow.com/docs)

Install
=======
 - As Rails plugin: `script/plugin install git://github.com/grosser/rpx_now.git `
 - As gem: `sudo gem install grosser-rpx_now --source http://gems.github.com/`

Examples
========

View
----
    #'mywebsite' is your subdomain/realm on RPX
    <%=RPXNow.embed_code('mywebsite',rpx_token_sessions_url)%>
    OR
    <%=RPXNow.popup_code('Login here...','mywebsite',rpx_token_sessions_url,:language=>'de')%>

`popup_code` can also be called with `:unobstrusive=>true`

Environment
-----------
    Rails::Initializer.run do |config|
      config.gem "grosser-rpx_now", :lib => "rpx_now", :source => "http://gems.github.com/"
      ...
    end
    RPXNow.api_key = "YOU RPX API KEY"

Controller
----------
    # user_data
    # found: {:name=>'John Doe', :username => 'john', :email=>'john@doe.com', :identifier=>'blug.google.com/openid/dsdfsdfs3f3'}
    # not found: nil (can happen with e.g. invalid tokens)
    def rpx_token
      raise "hackers?" unless data = RPXNow.user_data(params[:token])
      self.current_user = User.find_by_identifier(data[:identifier]) || User.create!(data)
      redirect_to '/'
    end

    # raw request processing
    RPXNow.user_data(params[:token]){|raw| {:email=>raw['profile']['verifiedEmail']} }

    # raw request with extended parameters (most users and APIs do not supply them)
    RPXNow.user_data(params[:token], :extended=>'true'){|raw| ...have a look at the RPX API DOCS...}

Advanced
--------
###Versions
    RPXNow.api_version = 2

###Mappings
You can map your primary keys (e.g. user.id) to identifiers, so that  
users can login to the same account with multiple identifiers.
    RPXNow.map(identifier, primary_key) #add a mapping
    RPXNow.unmap(identifier, primary_key) #remove a mapping
    RPXNow.mappings(primary_key) # [identifier1,identifier2,...]
    RPXNow.all_mappings # [["1",['google.com/dsdas','yahoo.com/asdas']], ["2",[...]], ... ]

After a primary key is mapped to an identifier, when a user logs in with this identifier,  
`RPXNow.user_data` will contain his `primaryKey` as `:id`.  
A identifyer can only belong to one user (in doubt the last one it was mapped to)

###User integration (e.g. ActiveRecord)
    class User < ActiveRecord::Base
      include RPXNow::UserIntegration
    end

    user.rpx.identifiers == RPXNow.mappings(user.id)
    user.rpx.map(identifier) == RPXNow.map(identifier, user.id)
    user.rpx.unmap(identifier) == RPXNow.unmap(identifier, user.id)

###Contacts (PRX Pro)
Retrieve all contacts for a given user:
    RPXNow.contacts(identifier).each {|c| puts "#{c['displayName']}: #{c['emails']}}

TODO
====
 - add provider / credentials helpers ?

Author
======
###Contributors
 - [DBA](http://github.com/DBA)
 - [dbalatero](http://github.com/dbalatero)

[Michael Grosser](http://pragmatig.wordpress.com)  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...  
