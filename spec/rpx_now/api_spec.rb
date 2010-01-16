require 'spec/spec_helper'

describe RPXNow::Api do
  describe 'ssl cert' do
    it "has an absolute path" do
      RPXNow::Api::SSL_CERT[0..0].should == File.expand_path( RPXNow::Api::SSL_CERT )[0..0] # start with '/' on *nix, drive letter on win
    end

    it "exists" do
      File.read(RPXNow::Api::SSL_CERT).to_s.should_not be_empty
    end
  end

  describe :parse_response do
    it "parses json when status is ok" do
      response = mock(:code=>'200', :body=>%Q({"stat":"ok","data":"xx"}))
      RPXNow::Api.send(:parse_response, response)['data'].should == "xx"
    end

    it "raises when there is a communication error" do
      response = stub(:code=>'200', :body=>%Q({"err":"wtf","stat":"ok"}))
      lambda{
        RPXNow::Api.send(:parse_response,response)
      }.should raise_error(RPXNow::ApiError)
    end

    it "raises when service has downtime" do
      response = stub(:code=>'200', :body=>%Q({"err":{"code":-1},"stat":"ok"}))
      lambda{
        RPXNow::Api.send(:parse_response,response)
      }.should raise_error(RPXNow::ServiceUnavailableError)
    end

    it "raises when service is down" do
      response = stub(:code=>'400',:body=>%Q({"stat":"err"}))
      lambda{
        RPXNow::Api.send(:parse_response,response)
      }.should raise_error(RPXNow::ServiceUnavailableError)
    end
  end

  describe :request_object do
    it "converts symbols to string keys" do
      mock = ''
      mock.should_receive(:form_data=).with([['symbol', 'value']])
      Net::HTTP::Post.should_receive(:new).and_return(mock)
      RPXNow::Api.send(:request_object, 'something', :symbol=>'value')
    end
  end
end