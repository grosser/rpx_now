require 'spec/spec_helper'

describe RPXNow::Request do
  describe :parse_response do
    it "parses json when status is ok" do
      response = mock(:code=>'200', :body=>%Q({"stat":"ok","data":"xx"}))
      RPXNow::Request.send(:parse_response, response)['data'].should == "xx"
    end

    it "raises when there is a communication error" do
      response = stub(:code=>'200', :body=>%Q({"err":"wtf","stat":"ok"}))
      lambda{
        RPXNow::Request.send(:parse_response,response)
      }.should raise_error(RPXNow::ApiError)
    end

    it "raises when service has downtime" do
      response = stub(:code=>'200', :body=>%Q({"err":{"code":-1},"stat":"ok"}))
      lambda{
        RPXNow::Request.send(:parse_response,response)
      }.should raise_error(RPXNow::ServiceUnavailableError)
    end

    it "raises when service is down" do
      response = stub(:code=>'400',:body=>%Q({"stat":"err"}))
      lambda{
        RPXNow::Request.send(:parse_response,response)
      }.should raise_error(RPXNow::ServiceUnavailableError)
    end
  end
end