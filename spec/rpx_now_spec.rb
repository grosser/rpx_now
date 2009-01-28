require File.expand_path("spec_helper", File.dirname(__FILE__))

API_KEY = '4b339169026742245b754fa338b9b0aebbd0a733'

describe RPXNow do
  describe :embed_code do
    it "contains the subdomain" do
      RPXNow.embed_code('xxx','my_url').should =~ /xxx/
    end
    it "contains the url" do
      RPXNow.embed_code('xxx','my_url').should =~ /token_url=my_url/
    end
  end

  describe :popup_code do
    it "defaults to english" do
      RPXNow.popup_code('x','y','z').should =~ /RPXNOW.language_preference = 'en'/
    end
    it "has a changeable language" do
      RPXNow.popup_code('x','y','z',:language=>'de').should =~ /RPXNOW.language_preference = 'de'/
    end
  end

  describe :user_data do
    def fake_response
      '{"profile":{"verifiedEmail":"grosser.michael@googlemail.com","displayName":"Michael Grosser","preferredUsername":"grosser.michael","identifier":"https:\/\/www.google.com\/accounts\/o8\/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM","email":"grosser.michael@gmail.com"},"stat":"ok"}'
    end
    it "is empty when used with an invalid token" do
      RPXNow.user_data('xxxx',API_KEY).should == nil
    end
    it "parses JSON response to user data" do
      RPXNow.expects(:post).returns fake_response
      RPXNow.user_data('','x').should == {:name=>'Michael Grosser',:email=>'grosser.michael@googlemail.com',:identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM"}
    end
    it "adds a :id when primaryKey was returned" do
      RPXNow.expects(:post).returns fake_response.sub('"verifiedEmail"','primaryKey:"2","verifiedEmail"')
      RPXNow.user_data('','x')[:id].should == 2
    end
    it "hands JSON response to supplied block" do
      RPXNow.expects(:post).returns "{x:1,stat:'ok'}"
      response = nil
      RPXNow.user_data('','x'){|data| response = data}
      response.should == {'x'=>1,'stat'=>'ok'}
    end
    it "returns what the supplied block returned" do
      RPXNow.expects(:post).returns "{x:1,stat:'ok'}"
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
      RPXNow.expects(:post).returns '{stat:"ok",data:"xx"}'
      RPXNow.send(:secure_json_post,'xx')['data'].should == 'xx'
    end
    it "raises when there is a communication error" do
      RPXNow.expects(:post).returns '{"err":"wtf",stat:"ok"}'
      lambda{RPXNow.send(:secure_json_post,'xx')}.should raise_error RPXNow::ServerError
    end
    it "raises when status is not ok" do
      RPXNow.expects(:post).returns '{"stat":"err"}'
      lambda{RPXNow.send(:secure_json_post,'xx')}.should raise_error RPXNow::ServerError
    end
  end

  describe :mappings do
    it "parses JSON response to unmap data" do
      RPXNow.expects(:post).returns '{"stat":"ok", "identifiers": ["http://test.myopenid.com/"]}'
      RPXNow.mappings(1, "x").should == ["http://test.myopenid.com/"]
    end
  end

  describe :map do
    it "adds a mapping" do
      RPXNow.expects(:post).returns '{"stat":"ok"}'
      RPXNow.map('http://test.myopenid.com',1, API_KEY)
    end
  end

  describe :unmap do
    it "unmaps a indentifier" do
      RPXNow.expects(:post).returns '{"stat":"ok"}'
      RPXNow.unmap('http://test.myopenid.com', 1, "x")
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
end