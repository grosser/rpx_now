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
 - for more advanced features have a look at the [RPX API Docs](https://rpxnow.com/docs)

Install
=======
 - As Rails plugin: `script/plugin install git://github.com/grosser/rpx_now.git `
 - As gem: `sudo gem install grosser-rpx_now --source http://gems.github.com/`
 - As gem from source: `git clone git://github.com/grosser/rpx_now.git`,`cd rpx_now`,`rake manifest`,`rake install`

Examples
========

View
----
    #login.erb
    #here 'mywebsite' is your subdomain/realm on RPX
    <%=RPXNow.embed_code('mywebsite',rpx_token_sessions_url)%>
    OR
    <%=RPXNow.popup_code('Login here...','mywebsite',rpx_token_sessions_url,:language=>'de')%>

Controller
----------
    # simple: use defaults
    def rpx_token
      data = RPXNew.user_data(params[:token],'YOUR RPX API KEY') # :name=>'John Doe',:email=>'john@doe.com',:identifier=>'blug.google.com/openid/dsdfsdfs3f3'
      #when no user_data was found, data is empty, you may want to handle that seperatly...
      #your user model must have an identifier column
      self.current_user = User.find_by_identifier(data[:identifier]) || User.create!(data)
      redirect_to '/'
    end

    # process the raw response yourself:
    RPXNew.user_data(params[:token],'YOUR RPX API KEY'){|raw| {:email=>raw['profile']['verifiedEmail']}}

    # request extended parameters (most users and APIs do not supply them)
    RPXNew.user_data(params[:token],'YOUR RPX API KEY',:extended=>'true'){|raw| ...have a look at the RPX API DOCS...}

Author
======
Michael Grosser  
grosser.michael@gmail.com  
Hereby placed under public domain, do what you want, just do not hold me accountable...  