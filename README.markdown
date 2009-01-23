Problem
=======
 - OpenID is complex
 - OpenID is not universally used

Solution
========
 - Use [RPX](http://rpxnow.com) for universal and usable user login
 - Make view/controller helpers for easy integration

Usage
=====
 - Get an API key @ [RPX](http://rpxnow.com)
 - Build login view
 - Communicate with RPX API in controller to create or login User

Install
=======
 - As Rails plugin: `script/plugin install git://github.com/grosser/rpx_now.git `
 - As gem: `sudo gem install grosser-rpx_now --source http://gems.github.com/`

Examples
========

View
----
    #login.erb
    #here 'mywebsite' is your subdomain on RPX
    <%=RPXNow.embed_code('mywebsite',rpx_token_sessions_url)%>

Controller
----------
    def rpx_token
      data = RPXNew.user_data(params[:token],'YOUR RPX API KEY') # :name=>'John Doe',:email=>'john@doe.com',:identifier=>'blug.google.com/openid/dsdfsdfs3f3'
      #when no user_data was found, data is empty, you may want to handle that seperatly...
      self.current_user = User.find_by_identifier(data[:identifier]) || User.create!(data)
      redirect_to '/'
    end

Author
======
Michael Grosser  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...  