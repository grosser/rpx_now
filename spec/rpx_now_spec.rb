require 'spec/spec_helper'

describe RPXNow do
  def fake_response(replace={})
    body = {'stat' => 'ok'}.merge(replace)
    mock({:code => "200", :body => body.to_json})
  end

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
      @response_body = {
        "profile" => {
          "verifiedEmail" => "grosser.michael@googlemail.com",
          "displayName" => "Michael Grosser",
          "preferredUsername" => "grosser.michael",
          "identifier" => "https:\/\/www.google.com\/accounts\/o8\/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM",
          "email" => "grosser.michael@gmail.com"
        }
      }
      @response = fake_response(@response_body)
      @fake_user_data = {'profile'=>{}}
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
      RPXNow::Request.should_receive(:request).and_return @response
      RPXNow.user_data('').should == expected
    end
    
    it "adds a :id when primaryKey was returned" do
      @response_body['profile']['primaryKey'] = "2"
      response = fake_response(@response_body)
      RPXNow::Request.should_receive(:request).and_return response
      RPXNow.user_data('')[:id].should == '2'
    end

    it "handles primaryKeys that are not numeric" do
      @response_body['profile']['primaryKey'] = "dbalatero"
      response = fake_response(@response_body)
      RPXNow::Request.should_receive(:request).and_return response
      RPXNow.user_data('')[:id].should == 'dbalatero'
    end
    
    it "hands JSON response to supplied block" do
      RPXNow::Request.should_receive(:request).and_return @response
      response = nil
      RPXNow.user_data(''){|data| response = data}
      response.delete('stat') # dunno why it happens, but is not important...
      response.should == @response_body
    end
    
    it "returns what the supplied block returned" do
      RPXNow::Request.should_receive(:request).and_return @response
      RPXNow.user_data(''){|data| "x"}.should == 'x'
    end
    
    it "can send additional parameters" do
      RPXNow::Request.should_receive(:request).with{|url,data|
        data[:extended].should == 'true'
      }.and_return @response
      RPXNow.user_data('',:extended=>'true')
    end

    it "works with api version as option" do
      RPXNow::Request.should_receive(:request).with('/api/v123/auth_info', :apiKey=>API_KEY, :token=>'id', :extended=>'abc').and_return @response
      RPXNow.user_data('id', :extended=>'abc', :api_version=>123)
      RPXNow.api_version.should == API_VERSION
    end

    it "works with apiKey as option" do
      RPXNow::Request.should_receive(:request).with('/api/v2/auth_info', :apiKey=>'THE KEY', :token=>'id', :extended=>'abc').and_return @response
      RPXNow.user_data('id', :extended=>'abc', :apiKey=>'THE KEY')
      RPXNow.api_key.should == API_KEY
    end
  end

  describe :set_status do
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
      response = fake_response(JSON.parse(File.read('spec/fixtures/get_contacts_response.json')))
      RPXNow::Request.should_receive(:request).with('/api/v2/get_contacts',:identifier=>'xx', :apiKey=>API_KEY).and_return response
      RPXNow.contacts('xx').size.should == 5
    end
  end

  describe :mappings do
    it "parses JSON response to unmap data" do

      RPXNow::Request.should_receive(:request).and_return fake_response("identifiers"  =>  ["http://test.myopenid.com/"])
      RPXNow.mappings(1).should == ["http://test.myopenid.com/"]
    end
  end

  describe :map do
    it "adds a mapping" do
      RPXNow::Request.should_receive(:request).and_return fake_response
      RPXNow.map('http://test.myopenid.com',1)
    end
  end

  describe :unmap do
    it "unmaps a indentifier" do
      RPXNow::Request.should_receive(:request).and_return fake_response
      RPXNow.unmap('http://test.myopenid.com', 1)
    end

    it "can be called with a specific version" do
      RPXNow::Request.should_receive(:request).with{|a,b|a == "/api/v300/unmap"}.and_return fake_response
      RPXNow.unmap('http://test.myopenid.com', 1, :api_key=>'xxx', :api_version=>300)
    end
  end

  it "has a VERSION" do
    RPXNow::VERSION.should =~ /^\d+\.\d+\.\d+$/
  end
end
