require File.expand_path("spec_helper", File.dirname(__FILE__))

API_KEY = '4b339169026742245b754fa338b9b0aebbd0a733'
API_VERSION = RPXNow.api_version

describe RPXNow do
  before do
    RPXNow.api_key = nil
    RPXNow.api_version = API_VERSION
  end

  describe :api_key= do
    it "stores the api key, so i do not have to supply everytime" do
      RPXNow.api_key='XX'
      RPXNow.expects(:post).with{|x,data|data[:apiKey]=='XX'}.returns %Q({"stat":"ok"})
      RPXNow.mappings(1)
    end
  end
  
  describe :api_version= do
    it "can be set to a api_version globally" do
      RPXNow.api_version = 5
      RPXNow.popup_code('x','y','z').should =~ %r(/openid/v5/signin)
    end
  end

  describe :embed_code do
    it "contains the subdomain" do
      RPXNow.embed_code('xxx','my_url').should =~ /xxx/
    end
    
    it "contains the url" do
      RPXNow.embed_code('xxx','my_url').should =~ /token_url=my_url/
    end
  end

  describe :popup_code do
    it "defaults to obtrusive output" do
      RPXNow.popup_code('sign on', 'subdomain', 'http://fake.domain.com/').should =~ /script src=/
    end
    
    it "can build an unobtrusive widget with specific version" do
      expected = %Q(<a class="rpxnow" href="https://subdomain.rpxnow.com/openid/v300/signin?token_url=http://fake.domain.com/">sign on</a>)
      RPXNow.popup_code('sign on', 'subdomain', 'http://fake.domain.com/', { :unobtrusive => true, :api_version => 300 }).should == expected
    end
    
    it "allows to specify the version of the widget" do
      RPXNow.popup_code('x','y','z', :api_version => 300).should =~ %r(/openid/v300/signin)
    end
    
    it "defaults to widget version 2" do
      RPXNow.popup_code('x','y','z').should =~ %r(/openid/v2/signin)
    end

    it "defaults to english" do
      RPXNow.popup_code('x','y','z').should =~ /RPXNOW.language_preference = 'en'/
    end
    
    it "has a changeable language" do
      RPXNow.popup_code('x','y','z',:language=>'de').should =~ /RPXNOW.language_preference = 'de'/
    end
  end

  describe :user_data do
    def fake_response
      %Q({"profile":{"verifiedEmail":"grosser.michael@googlemail.com","displayName":"Michael Grosser","preferredUsername":"grosser.michael","identifier":"https:\/\/www.google.com\/accounts\/o8\/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM","email":"grosser.michael@gmail.com"},"stat":"ok"})
    end
    
    it "is empty when used with an invalid token" do
      RPXNow.user_data('xxxx',API_KEY).should == nil
    end
    
    it "is empty when used with an unknown token" do
      RPXNow.user_data('60d8c6374f4e9d290a7b55f39da7cc6435aef3d3',API_KEY).should == nil
    end
    
    it "parses JSON response to user data" do
      RPXNow.expects(:post).returns fake_response
      RPXNow.user_data('','x').should == {:name=>'Michael Grosser',:email=>'grosser.michael@googlemail.com',:identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM", :username => 'grosser.michael'}
    end
    
    it "adds a :id when primaryKey was returned" do
      RPXNow.expects(:post).returns fake_response.sub(%Q("verifiedEmail"), %Q("primaryKey":"2","verifiedEmail"))
      RPXNow.user_data('','x')[:id].should == '2'
    end

    it "handles primaryKeys that are not numeric" do
      RPXNow.expects(:post).returns fake_response.sub(%Q("verifiedEmail"), %Q("primaryKey":"dbalatero","verifiedEmail"))
      RPXNow.user_data('','x')[:id].should == 'dbalatero'
    end
    
    it "hands JSON response to supplied block" do
      RPXNow.expects(:post).returns %Q({"x":"1","stat":"ok"})
      response = nil
      RPXNow.user_data('','x'){|data| response = data}
      response.should == {"x" => "1", "stat" => "ok"}
    end
    
    it "returns what the supplied block returned" do
      RPXNow.expects(:post).returns %Q({"x":"1","stat":"ok"})
      RPXNow.user_data('','x'){|data| "x"}.should == 'x'
    end
    
    it "can send additional parameters" do
      RPXNow.expects(:post).with{|url,data|
        data[:extended].should == 'true'
      }.returns fake_response
      RPXNow.user_data('','x',:extended=>'true')
    end
  end

  describe :read_user_data_from_response do
    it "reads secondary names" do
      RPXNow.send(:read_user_data_from_response,{'profile'=>{'preferredUsername'=>'1'}})[:name].should == '1'
    end
    
    it "parses email when no name is found" do
      RPXNow.send(:read_user_data_from_response,{'profile'=>{'email'=>'1@xxx.com'}})[:name].should == '1'
    end
  end

  describe :secure_json_post do
    it "parses json when status is ok" do
      RPXNow.expects(:post).returns %Q({"stat":"ok","data":"xx"})
      RPXNow.send(:secure_json_post, %Q("yy"))['data'].should == "xx"
    end
    
    it "raises when there is a communication error" do
      RPXNow.expects(:post).returns %Q({"err":"wtf","stat":"ok"})
      lambda{RPXNow.send(:secure_json_post,'xx')}.should raise_error RPXNow::ServerError
    end
    
    it "raises when status is not ok" do
      RPXNow.expects(:post).returns %Q({"stat":"err"})
      lambda{RPXNow.send(:secure_json_post,'xx')}.should raise_error RPXNow::ServerError
    end
  end

  describe :mappings do
    it "parses JSON response to unmap data" do
      RPXNow.expects(:post).returns %Q({"stat":"ok", "identifiers": ["http://test.myopenid.com/"]})
      RPXNow.mappings(1, "x").should == ["http://test.myopenid.com/"]
    end
  end

  describe :map do
    it "adds a mapping" do
      RPXNow.expects(:post).returns %Q({"stat":"ok"})
      RPXNow.map('http://test.myopenid.com',1, API_KEY)
    end
  end

  describe :unmap do
    it "unmaps a indentifier" do
      RPXNow.expects(:post).returns %Q({"stat":"ok"})
      RPXNow.unmap('http://test.myopenid.com', 1, "x")
    end

    it "can be called with a specific version" do
      RPXNow.expects(:secure_json_post).with{|a,b|a == "https://rpxnow.com/api/v300/unmap"}
      RPXNow.unmap('http://test.myopenid.com', 1, :api_key=>'xxx', :api_version=>300)
    end
  end

  describe :mapping_integration do
    before do
      @k1 = 'http://test.myopenid.com'
      RPXNow.unmap(@k1, 1, API_KEY)
      @k2 = 'http://test-2.myopenid.com'
      RPXNow.unmap(@k2, 1, API_KEY)
    end

    it "has no mappings when nothing was mapped" do
      RPXNow.mappings(1,API_KEY).should == []
    end

    it "unmaps mapped keys" do
      RPXNow.map(@k2, 1, API_KEY)
      RPXNow.unmap(@k2, 1, API_KEY)
      RPXNow.mappings(1, API_KEY).should == []
    end

    it "maps keys to a primary key and then retrieves them" do
      RPXNow.map(@k1, 1, API_KEY)
      RPXNow.map(@k2, 1, API_KEY)
      RPXNow.mappings(1,API_KEY).sort.should == [@k2,@k1]
    end

    it "does not add duplicate mappings" do
      RPXNow.map(@k1, 1, API_KEY)
      RPXNow.map(@k1, 1, API_KEY)
      RPXNow.mappings(1,API_KEY).should == [@k1]
    end
  end
  
  describe :to_query do
    it "should not depend on active support" do
      RPXNow.send('to_query', {:one => " abc"}).should == "one= abc"
    end
    
    it "should use ActiveSupport core extensions" do
      require 'activesupport'
      RPXNow.send('to_query', {:one => " abc"}).should == "one=+abc"
    end
  end
end
