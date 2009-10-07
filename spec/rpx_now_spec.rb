require 'spec/spec_helper'

describe RPXNow do
  describe :api_key= do
    it "stores the api key, so i do not have to supply everytime" do
      RPXNow.api_key='XX'
      RPXNow::Request.should_receive(:request).with{|x,data|data[:apiKey]=='XX'}.and_return mock(:code=>'200', :body=>%Q({"stat":"ok"}))
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
    
    it "defaults to English" do
      RPXNow.embed_code('xxx', 'my_url').should =~ /language_preference=en/
    end
    
    it "has a changeable language" do
      RPXNow.embed_code('xxx', 'my_url', :language => 'es').should =~ /language_preference=es/
    end
    
    it "defaults to 400px width" do
      RPXNow.embed_code('xxx', 'my_url').should =~ /width:400px;/
    end
    
    it "has a changeable width" do
      RPXNow.embed_code('xxx', 'my_url', :width => '300').should =~ /width:300px;/
    end
    
    it "defaults to 240px height" do
      RPXNow.embed_code('xxx', 'my_url').should =~ /height:240px;/
    end
    
    it "has a changeable height" do
      RPXNow.embed_code('xxx', 'my_url', :height => '500').should =~ /height:500px;/
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
    before do
      @response_body = %Q({"profile":{"verifiedEmail":"grosser.michael@googlemail.com","displayName":"Michael Grosser","preferredUsername":"grosser.michael","identifier":"https:\/\/www.google.com\/accounts\/o8\/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM","email":"grosser.michael@gmail.com"},"stat":"ok"})
      @fake_user_data = {'profile'=>{}}
    end

    def fake_response
      mock(:code=>"200",:body=>@response_body)
    end
    
    it "raises ApiError when used with an invalid token" do
      lambda{
        RPXNow.user_data('xxxx')
      }.should raise_error(RPXNow::ApiError)
    end
    
    it "is empty when used with an unknown token" do
      RPXNow.user_data('60d8c6374f4e9d290a7b55f39da7cc6435aef3d3').should == nil
    end
    
    it "parses JSON response to user data" do
      expected = {
        :name       => 'Michael Grosser',
        :email      => 'grosser.michael@googlemail.com',
        :identifier => 'https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM',
        :username   => 'grosser.michael',
      }
      RPXNow::Request.should_receive(:request).and_return fake_response
      RPXNow.user_data('').should == expected
    end
    
    it "adds a :id when primaryKey was returned" do
      @response_body.sub!(%Q("verifiedEmail"), %Q("primaryKey":"2","verifiedEmail"))
      RPXNow::Request.should_receive(:request).and_return fake_response
      RPXNow.user_data('')[:id].should == '2'
    end

    it "handles primaryKeys that are not numeric" do
      @response_body.sub!(%Q("verifiedEmail"), %Q("primaryKey":"dbalatero","verifiedEmail"))
      RPXNow::Request.should_receive(:request).and_return fake_response
      RPXNow.user_data('')[:id].should == 'dbalatero'
    end
    
    it "hands JSON response to supplied block" do
      RPXNow::Request.should_receive(:request).and_return mock(:code=>'200',:body=>%Q({"x":"1","stat":"ok"}))
      response = nil
      RPXNow.user_data(''){|data| response = data}
      response.should == {"x" => "1", "stat" => "ok"}
    end
    
    it "returns what the supplied block returned" do
      RPXNow::Request.should_receive(:request).and_return mock(:code=>'200',:body=>%Q({"x":"1","stat":"ok"}))
      RPXNow.user_data(''){|data| "x"}.should == 'x'
    end
    
    it "can send additional parameters" do
      RPXNow::Request.should_receive(:request).with{|url,data|
        data[:extended].should == 'true'
      }.and_return fake_response
      RPXNow.user_data('',:extended=>'true')
    end

    it "works with api key as 2nd parameter (backwards compatibility)" do
      RPXNow.should_receive(:secure_json_post).with('/api/v2/auth_info', :apiKey=>'THE KEY', :token=>'id').and_return @fake_user_data
      RPXNow.user_data('id', 'THE KEY')
      RPXNow.api_key.should == API_KEY
    end

    it "works with api key as 2nd parameter and options (backwards compatibility)" do
      RPXNow.should_receive(:secure_json_post).with('/api/v2/auth_info', :apiKey=>'THE KEY', :extended=>'abc', :token=>'id' ).and_return @fake_user_data
      RPXNow.user_data('id', 'THE KEY', :extended=>'abc')
      RPXNow.api_key.should == API_KEY
    end

    it "works with api version as option (backwards compatibility)" do
      RPXNow.should_receive(:secure_json_post).with('/api/v123/auth_info', :apiKey=>API_KEY, :token=>'id', :extended=>'abc').and_return @fake_user_data
      RPXNow.user_data('id', :extended=>'abc', :api_version=>123)
      RPXNow.api_version.should == API_VERSION
    end
  end

  describe :set_status do
    before do
      @response_body = %Q({ "stat": "ok" })
    end

    def fake_response
      mock(:code=>"200",:body=>@response_body)
    end

    it "parses JSON response to result hash" do
      RPXNow::Request.should_receive(:request).and_return fake_response
      RPXNow.set_status('identifier', 'Chillen...').should == {'stat' => 'ok'}
    end
  end

  describe :read_user_data_from_response do
    it "reads secondary names" do
      RPXNow.send(:parse_user_data,{'profile'=>{'preferredUsername'=>'1'}})[:name].should == '1'
    end
    
    it "parses email when no name is found" do
      RPXNow.send(:parse_user_data,{'profile'=>{'email'=>'1@xxx.com'}})[:name].should == '1'
    end
  end

  describe :contacts do
    it "finds all contacts" do
      response = JSON.parse(File.read('spec/fixtures/get_contacts_response.json'))
      RPXNow.should_receive(:secure_json_post).with('/api/v2/get_contacts',:identifier=>'xx', :apiKey=>API_KEY).and_return response
      RPXNow.contacts('xx').size.should == 5
    end
  end

  describe :mappings do
    it "parses JSON response to unmap data" do
      RPXNow::Request.should_receive(:request).and_return mock(:code=>'200',:body=>%Q({"stat":"ok", "identifiers": ["http://test.myopenid.com/"]}))
      RPXNow.mappings(1, "x").should == ["http://test.myopenid.com/"]
    end
  end

  describe :map do
    it "adds a mapping" do
      RPXNow::Request.should_receive(:request).and_return mock(:code=>'200',:body=>%Q({"stat":"ok"}))
      RPXNow.map('http://test.myopenid.com',1, API_KEY)
    end
  end

  describe :unmap do
    it "unmaps a indentifier" do
      RPXNow::Request.should_receive(:request).and_return mock(:code=>'200',:body=>%Q({"stat":"ok"}))
      RPXNow.unmap('http://test.myopenid.com', 1, "x")
    end

    it "can be called with a specific version" do
      RPXNow.should_receive(:secure_json_post).with{|a,b|a == "/api/v300/unmap"}
      RPXNow.unmap('http://test.myopenid.com', 1, :api_key=>'xxx', :api_version=>300)
    end
  end

  describe :mapping_integration do
    before do
      @k1 = 'http://test.myopenid.com'
      RPXNow.unmap(@k1, 1)
      @k2 = 'http://test-2.myopenid.com'
      RPXNow.unmap(@k2, 1)
    end

    it "has no mappings when nothing was mapped" do
      RPXNow.mappings(1).should == []
    end

    it "unmaps mapped keys" do
      RPXNow.map(@k2, 1)
      RPXNow.unmap(@k2, 1)
      RPXNow.mappings(1).should == []
    end

    it "maps keys to a primary key and then retrieves them" do
      RPXNow.map(@k1, 1)
      RPXNow.map(@k2, 1)
      RPXNow.mappings(1).sort.should == [@k2,@k1]
    end

    it "does not add duplicate mappings" do
      RPXNow.map(@k1, 1)
      RPXNow.map(@k1, 1)
      RPXNow.mappings(1).should == [@k1]
    end

    it "finds all mappings" do
      RPXNow.map(@k1, 1)
      RPXNow.map(@k2, 2)
      RPXNow.all_mappings.sort.should == [["1", ["http://test.myopenid.com"]], ["2", ["http://test-2.myopenid.com"]]]
    end
  end
end
