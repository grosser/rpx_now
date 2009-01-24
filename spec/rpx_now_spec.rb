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
      silence_warnings do
        RPXNow.user_data('xxxx',API_KEY).should == nil
      end
    end
    it "raises when api-key is missing" do
      lambda{RPXNow.user_data('xxx','').should raise_error('NO API KEY')}
    end
    it "parses JSON response to user data" do
      RPXNow.expects(:post).returns fake_response
      RPXNow.user_data('','x').should == {:name=>'Michael Grosser',:email=>'grosser.michael@googlemail.com',:identifier=>"https://www.google.com/accounts/o8/id?id=AItOawmaOlyYezg_WfbgP_qjaUyHjmqZD9qNIVM"}
    end
    it "hands JSON response to supplied block" do
      RPXNow.expects(:post).returns "{x:1}"
      response = nil
      RPXNow.user_data('','x'){|data| response = data}
      response.should == {'x'=>1}
    end
    it "returns what the supplied block returned" do
      RPXNow.expects(:post).returns "{x:1}"
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
end