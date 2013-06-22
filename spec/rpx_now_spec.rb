require 'spec_helper'

describe RPXNow do
  def fake_response(replace={})
    body = {'stat' => 'ok'}.merge(replace)
    mock({:code => "200", :body => body.to_json})
  end

  describe :domain do
    it 'defaults to rpxnow.com' do
      RPXNow.domain.should == 'rpxnow.com'
    end
  end

  describe :domain= do
    it "is stored" do
      RPXNow.domain = 'domain.com'
      RPXNow.domain.should == 'domain.com'
    end
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

    it "has id on iframe" do
      RPXNow.embed_code('xxx','my_url').should =~ /id=\"rpx_now_embed\"/
    end
  end

  describe :popup_code do
    let(:text) { 'sign on' }
    let(:subdomain) { 'subdomain' }
    let(:url) { 'http://fake.domain.com/' }
    let(:options) { {} }

    context 'when obtrusive (default)' do
      subject { RPXNow.popup_code(text, subdomain, url, options ) }

      it "defaults to obtrusive output" do
         should =~ /script src=/
      end

      it "does not change supplied options" do
        options = {:xxx => 1}
        RPXNow.popup_code('a','b','c', options)
        options.should == {:xxx => 1}
      end

      context "with html link id specified" do
        let(:options) { {:html => {:id => "xxxx"}} }
        it { should =~ /id="xxxx"/ }
      end

      context "with html link class specified" do
        let(:options) { {:html => {:class => "c1 c2"}} }
        it { should =~ /class="rpxnow c1 c2"/ }
      end

      it "does not encode token_url for popup" do
        expected = %Q(RPXNOW.token_url = 'http://fake.domain.com/')
        should include(expected)
      end

      describe 'fallback url' do
        it "encodes token_url" do
          should include(%Q(<a class="rpxnow" href="https://subdomain.rpxnow.com/openid/embed?token_url=http%3A%2F%2Ffake.domain.com%2F">sign on</a>))
        end
        context "when html href options provided" do
          let(:options) { {:html => {:href => "http://go.here.instead"}} }
          it { should include(%Q(<a class="rpxnow" href="http://go.here.instead">sign on</a>)) }
        end
      end

      context "with api_version specified" do
        let(:options) { {:api_version => 300} }
        it { should_not include("openid/v300/signin") }
      end

      describe 'language' do
        it "defaults to no language" do
          should_not =~ /RPXNOW.language_preference/
        end
        context "when specified" do
          let(:options) { {:language=>'de'} }
          it { should =~ /RPXNOW.language_preference = 'de'/ }
        end
      end

      describe 'flags' do
        it "defaults to no language" do
          should_not =~ /RPXNOW.flags/
        end
        context "when specified" do
          let(:options) { {:flags=>'test'} }
          it { should =~ /RPXNOW.flags = 'test'/ }
        end
      end

      describe 'default_provider' do
        it "defaults to no provider" do
          should_not =~ /RPXNOW.default_provider/
        end
        context "when specified" do
          let(:options) { {:default_provider=>'test'} }
          it { should =~ /RPXNOW.default_provider = 'test'/ }
        end
      end

    end

    context 'when unobtrusive' do
      subject { RPXNow.popup_code(text, subdomain, url, {:unobtrusive => true}.merge(options) ) }

      describe 'fallback url' do
        it "encodes token_url" do
          should == %Q(<a class="rpxnow" href="https://subdomain.rpxnow.com/openid/embed?token_url=http%3A%2F%2Ffake.domain.com%2F">sign on</a>)
        end
        context "when html href options provided" do
          let(:options) { {:html => {:href => "http://go.here.instead"}} }
          it { should include(%Q(<a class="rpxnow" href="http://go.here.instead">sign on</a>)) }
        end
      end

      context "with api_version specified" do
        let(:options) { {:api_version => 'XX'} }
        it { should_not include('XX') }
      end

      describe 'language' do
        it "defaults to no language" do
          should_not include('language_preference')
        end
        context "when specified" do
          let(:options) { {:language=>'de'} }
          it { should include("language_preference=de") }
        end
      end

      describe 'flags' do
        it "defaults to no language" do
          should_not include('flags')
        end
        context "when specified" do
          let(:options) { {:flags=>'test'} }
          it { should include("flags=test") }
        end
      end

      describe 'default_provider' do
        it "defaults to no provider" do
          should_not include('default_provider')
        end
        context "when specified" do
          let(:options) { {:default_provider=>'test'} }
          it { should include("default_provider=test") }
        end
      end
    end

    context "when fallback_url :legacy" do
      context 'when obtrusive (default)' do
        subject { RPXNow.popup_code(text, subdomain, url, {:fallback_url => :legacy}.merge(options) ) }

        describe 'fallback url' do
          it "encodes token_url" do
            should include(%Q(<a class="rpxnow" href="https://subdomain.rpxnow.com/openid/v2/signin?token_url=http%3A%2F%2Ffake.domain.com%2F">sign on</a>))
          end
          context "when html href options provided" do
            let(:options) { {:html => {:href => "http://go.here.instead"}} }
            it { should include(%Q(<a class="rpxnow" href="http://go.here.instead">sign on</a>)) }
          end
        end

        it "defaults to widget version 2" do
          should =~ %r(/openid/v2/signin)
        end

        context "with api_version specified" do
          let(:options) { {:api_version => 300} }
          it { should include("openid/v300/signin?") }
        end

      end

      context 'and unobtrusive' do
        subject { RPXNow.popup_code(text, subdomain, url, {:fallback_url => :legacy, :unobtrusive => true}.merge(options) ) }

        describe 'fallback url' do
          it "encodes token_url" do
            should == %Q(<a class="rpxnow" href="https://subdomain.rpxnow.com/openid/v2/signin?token_url=http%3A%2F%2Ffake.domain.com%2F">sign on</a>)
          end
          context "when html href options provided" do
            let(:options) { {:html => {:href => "http://go.here.instead"}} }
            it { should include(%Q(<a class="rpxnow" href="http://go.here.instead">sign on</a>)) }
          end
        end

        context "with api_version specified" do
          let(:options) { {:api_version => 'XX'} }
          it { should include("openid/vXX/signin?") }
        end

      end
    end

    context "when fallback_url :disable" do
      context 'when obtrusive (default)' do
        subject { RPXNow.popup_code(text, subdomain, url, {:fallback_url => :disable}.merge(options) ) }

        describe 'fallback url' do
          it "encodes token_url" do
            should include(%Q(<a class="rpxnow" href="javacsript:void(0)">sign on</a>))
          end
          context "when html href options provided" do
            let(:options) { {:html => {:href => "http://go.here.instead"}} }
            it { should include(%Q(<a class="rpxnow" href="http://go.here.instead">sign on</a>)) }
          end
        end

        context "with api_version specified" do
          let(:options) { {:api_version => 300} }
          it { should_not include("openid/v300/signin?") }
        end

      end

      context 'and unobtrusive' do
        subject { RPXNow.popup_code(text, subdomain, url, {:fallback_url => :disable, :unobtrusive => true}.merge(options) ) }

        describe 'fallback url' do
          it "encodes token_url" do
            should == %Q(<a class="rpxnow" href="javacsript:void(0)">sign on</a>)
          end
          context "when html href options provided" do
            let(:options) { {:html => {:href => "http://go.here.instead"}} }
            it { should include(%Q(<a class="rpxnow" href="http://go.here.instead">sign on</a>)) }
          end
        end

        context "with api_version specified" do
          let(:options) { {:api_version => 300} }
          it { should_not include("openid/v300/signin?") }
        end

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
      pending "this now fails with RPXNow::ServiceUnavailableError. Have expectations changed? See issue #20"
      lambda{
        RPXNow.user_data('xxxx')
      }.should raise_error(RPXNow::ApiError)
    end

    it "is empty when used with an unknown token" do
      pending "this now fails with RPXNow::ServiceUnavailableError. Have expectations changed? See issue #20"
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

    it "deprecated: adds raw profile data if i want it" do
      RPXNow::Api.should_receive(:request).and_return @response
      RPXNow.should_receive(:warn)
      RPXNow.user_data('',:additional => [:raw])[:raw]["verifiedEmail"].should == "grosser.michael@googlemail.com"
    end

    it "adds raw data if i want it" do
      RPXNow::Api.should_receive(:request).and_return @response
      RPXNow.user_data('',:additional => [:raw_response])[:raw_response]['profile']["verifiedEmail"].should == "grosser.michael@googlemail.com"
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

    it "can request extended data" do
      RPXNow::Api.should_receive(:request).
        with(anything, hash_including(:extended => true)).
        and_return @response
      RPXNow.user_data('', :extended=>true)
    end

    it "returns extended data as an additional field" do
      @response_body['friends'] = {'x' => 1}
      @response = fake_response(@response_body)

      RPXNow::Api.should_receive(:request).and_return @response
      RPXNow.user_data('', :extended=>true)[:extended].should == {'friends' => {'x' => 1}}
    end

    it "does not pass raw_response to RPX" do
      RPXNow::Api.should_receive(:request).
        with(anything, hash_not_including(:raw_response => true)).
        and_return @response
      RPXNow.user_data('', :raw_response=>true)
    end

    it "can return a raw_response" do
      RPXNow::Api.should_receive(:request).and_return @response
      RPXNow.user_data('', :raw_response=>true).should == @response_body.merge('stat' => 'ok')
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

  describe :activity do
    it "does a api call with the right arguments" do
      RPXNow::Api.should_receive(:request).with("/api/v2/activity", :identifier=>"identifier", :activity=>'{"test":"something"}', :apiKey=>API_KEY).and_return fake_response
      RPXNow.activity('identifier', :test => 'something')
    end

    it "can pass identifier/apiKey" do
      RPXNow::Api.should_receive(:request).with("/api/v66666/activity", hash_including(:apiKey=>'MYKEY')).and_return fake_response
      RPXNow.activity('identifier', {:test => 'something'}, :apiKey => 'MYKEY', :api_version => '66666')
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
