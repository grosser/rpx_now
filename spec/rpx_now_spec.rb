require 'spec/spec_helper'

describe RPXNow do
  def fake_response(replace={})
    body = {'stat' => 'ok'}.merge(replace)
    mock({:code => "200", :body => body.to_json})
  end

  describe :api_key= do
    before do
      RPXNow.api_key='XX'
    end

    it "is stored" do
      RPXNow.api_key.should == 'XX'
    end

    it "stores the api key, so i do not have to supply everytime" do
      RPXNow::Api.should_receive(:request).
        with(anything, hash_including(:apiKey => 'XX')).
        and_return fake_response
      RPXNow.mappings(1)
    end

    it "is not overwritten when overwriting for a single request" do
      RPXNow::Api.should_receive(:request).
        with(anything, hash_including(:apiKey => 'YY')).
        and_return fake_response
      RPXNow.mappings(1, :apiKey => 'YY')
      RPXNow.api_key.should == 'XX'
    end
  end
  
  describe :api_version= do
    it "is 2 by default" do
      RPXNow.api_version.should == 2
    end

    it "is stored" do
      RPXNow.api_version='XX'
      RPXNow.api_version.should == 'XX'
    end

    it "used for every request" do
      RPXNow.api_version='XX'
      RPXNow::Api.should_receive(:request).
        with('/api/vXX/mappings', anything).
        and_return fake_response
      RPXNow.mappings(1)
    end

    it "is not overwritten when overwriting for a single request" do
      RPXNow.api_version='XX'
      RPXNow::Api.should_receive(:request).
        with('/api/vYY/mappings', anything).
        and_return fake_response
      RPXNow.mappings(1, :api_version => 'YY')
      RPXNow.api_version.should == 'XX'
    end

    it "is not passed in data for request" do
      RPXNow.api_version='XX'
      RPXNow::Api.should_receive(:request).
        with(anything, hash_not_including(:api_version => 'YY')).
        and_return fake_response
      RPXNow.mappings(1, :api_version => 'YY')
    end
  end

  describe :embed_code do
    it "contains the subdomain" do
      RPXNow.embed_code('xxx','my_url').should =~ /xxx/
    end
    
    it "contains the url" do
      RPXNow.embed_code('xxx','my_url').should =~ /token_url=my_url/
    end
    
    it "defaults to no language" do
      RPXNow.embed_code('xxx', 'my_url').should_not =~ /language_preference/
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

    it "does not change supplied options" do
      options = {:xxx => 1}
      RPXNow.popup_code('a','b','c', options)
      options.should == {:xxx => 1}
    end

    describe 'obstrusive' do
      it "does not encode token_url for popup" do
        expected = %Q(RPXNOW.token_url = 'http://fake.domain.com/')
        RPXNow.popup_code('sign on', 'subdomain', 'http://fake.domain.com/').should include(expected)
      end
      it "encodes token_url for unobtrusive fallback link" do
        expected = %Q(<a class="rpxnow" href="https://subdomain.rpxnow.com/openid/v2/signin?token_url=http%3A%2F%2Ffake.domain.com%2F">sign on</a>)
        RPXNow.popup_code('sign on', 'subdomain', 'http://fake.domain.com/').should include(expected)
      end
    end
    
    describe 'unobstrusive' do
      it "can build an unobtrusive widget with encoded token_url" do
        expected = %Q(<a class="rpxnow" href="https://subdomain.rpxnow.com/openid/v2/signin?token_url=http%3A%2F%2Ffake.domain.com%2F">sign on</a>)
        actual = RPXNow.popup_code('sign on', 'subdomain', 'http://fake.domain.com/', :unobtrusive => true)
        actual.should == expected
      end

      it "can change api version" do
        RPXNow.popup_code('x', 'y', 'z', :unobtrusive => true, :api_version => 'XX').should include("openid/vXX/signin?")
      end

      it "can change language" do
        RPXNow.popup_code('x', 'y', 'z', :unobtrusive => true, :language => 'XX').should include("language_preference=XX")
      end

      it "can add flags" do
        RPXNow.popup_code('x', 'y', 'z', :unobtrusive => true, :flags => 'test').should include("flags=test")
      end

      it "can add default_provider" do
        RPXNow.popup_code('x', 'y', 'z', :unobtrusive => true, :default_provider => 'test').should include("default_provider=test")
      end
    end

    it "allows to specify the version of the widget" do
      RPXNow.popup_code('x','y','z', :api_version => 300).should =~ %r(/openid/v300/signin)
    end
    
    it "defaults to widget version 2" do
      RPXNow.popup_code('x','y','z').should =~ %r(/openid/v2/signin)
    end

    describe 'language' do
      it "defaults to no language" do
        RPXNow.popup_code('x','y','z').should_not =~ /RPXNOW.language_preference/
      end

      it "has a changeable language" do
        RPXNow.popup_code('x','y','z', :language=>'de').should =~ /RPXNOW.language_preference = 'de'/
      end
    end

    describe 'flags' do
      it "defaults to no language" do
        RPXNow.popup_code('x','y','z').should_not =~ /RPXNOW.flags/
      end

      it "can have flags" do
        RPXNow.popup_code('x','y','z', :flags=>'test').should =~ /RPXNOW.flags = 'test'/
      end
    end

    describe 'default_provider' do
      it "defaults to no provider" do
        RPXNow.popup_code('x','y','z').should_not =~ /RPXNOW.default_provider/
      end

      it "can have default_provider" do
        RPXNow.popup_code('x','y','z', :default_provider=>'test').should =~ /RPXNOW.default_provider = 'test'/
      end
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
      RPXNow::Api.should_receive(:request).and_return @response
      RPXNow.user_data('').should == expected
    end
    
    it "adds a :id when primaryKey was returned" do
      @response_body['profile']['primaryKey'] = "2"
      response = fake_response(@response_body)
      RPXNow::Api.should_receive(:request).and_return response
      RPXNow.user_data('')[:id].should == '2'
    end

    it "handles primaryKeys that are not numeric" do
      @response_body['profile']['primaryKey'] = "dbalatero"
      response = fake_response(@response_body)
      RPXNow::Api.should_receive(:request).and_return response
      RPXNow.user_data('')[:id].should == 'dbalatero'
    end

    it "can fetch additional fields" do
      @response_body['profile']['xxxy'] = "test"
      response = fake_response(@response_body)
      RPXNow::Api.should_receive(:request).and_return response
      RPXNow.user_data('', :additional => [:xxxy])[:xxxy].should == 'test'
    end
    
    it "hands JSON response to supplied block" do
      RPXNow::Api.should_receive(:request).and_return @response
      response = nil
      RPXNow.user_data(''){|data| response = data}
      response.delete('stat') # dunno why it happens, but is not important...
      response.should == @response_body
    end
    
    it "returns what the supplied block returned" do
      RPXNow::Api.should_receive(:request).and_return @response
      RPXNow.user_data(''){|data| "x"}.should == 'x'
    end
    
    it "can send additional parameters" do
      RPXNow::Api.should_receive(:request).
        with(anything, hash_including(:extended => 'true')).
        and_return @response
      RPXNow.user_data('',:extended=>'true')
    end

    # these 2 tests are kind of duplicates of the api_version/key tests,
    # but i want to be extra-sure user_data works
    it "works with api version as option" do
      RPXNow::Api.should_receive(:request).
        with('/api/v123/auth_info', anything).
        and_return @response
      RPXNow.user_data('id', :extended=>'abc', :api_version=>123)
      RPXNow.api_version.should == API_VERSION
    end

    it "works with apiKey as option" do
      RPXNow::Api.should_receive(:request).
        with('/api/v2/auth_info', hash_including(:apiKey=>'THE KEY')).
        and_return @response
      RPXNow.user_data('id', :extended=>'abc', :apiKey=>'THE KEY')
      RPXNow.api_key.should == API_KEY
    end
  end

  describe :set_status do
    it "sets the status" do
      RPXNow::Api.should_receive(:request).
        with("/api/v2/set_status", :identifier=>"identifier", :status=>"Chillen...", :apiKey=>API_KEY).
        and_return fake_response
      RPXNow.set_status('identifier', 'Chillen...')
    end
  end

  describe :parse_user_data do
    it "reads secondary names" do
      RPXNow.send(:parse_user_data,{'profile'=>{'preferredUsername'=>'1'}}, {})[:name].should == '1'
    end
    
    it "parses email when no name is found" do
      RPXNow.send(:parse_user_data,{'profile'=>{'email'=>'1@xxx.com'}}, {})[:name].should == '1'
    end
  end

  describe :contacts do
    it "finds all contacts" do
      response = fake_response(JSON.parse(File.read('spec/fixtures/get_contacts_response.json')))
      RPXNow::Api.should_receive(:request).
        with('/api/v2/get_contacts',:identifier=>'xx', :apiKey=>API_KEY).
        and_return response
      RPXNow.contacts('xx').size.should == 5
    end
  end

  describe :mappings do
    it "shows all mappings" do
      RPXNow::Api.should_receive(:request).
        with("/api/v2/mappings", :apiKey=>API_KEY, :primaryKey=>1).
        and_return fake_response("identifiers" => ["http://test.myopenid.com/"])
      RPXNow.mappings(1).should == ["http://test.myopenid.com/"]
    end
  end

  describe :map do
    it "maps a identifier" do
      RPXNow::Api.should_receive(:request).
        with("/api/v2/map", :apiKey=>API_KEY, :primaryKey=>1, :identifier=>"http://test.myopenid.com").
        and_return fake_response
      RPXNow.map('http://test.myopenid.com',1)
    end
  end

  describe :unmap do
    it "unmaps a indentifier" do
      RPXNow::Api.should_receive(:request).
        with("/api/v2/unmap", :apiKey=>API_KEY, :primaryKey=>1, :identifier=>"http://test.myopenid.com").
        and_return fake_response
      RPXNow.unmap('http://test.myopenid.com', 1)
    end
  end

  it "has a VERSION" do
    RPXNow::VERSION.should =~ /^\d+\.\d+\.\d+$/
  end
end
