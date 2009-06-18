require File.expand_path("../spec_helper", File.dirname(__FILE__))

class User
  include RPXNow::UserIntegration

  def id
    5
  end
end

describe RPXNow::UserProxy do
  before do
    RPXNow.unmap('http://test.myopenid.com', 5)
  end

  it "has identifiers" do
    RPXNow.map('http://test.myopenid.com', 5)
    User.new.rpx.identifiers.should == ['http://test.myopenid.com']
  end

  it "can map" do
    User.new.rpx.map('http://test.myopenid.com')
    User.new.rpx.identifiers.should == ['http://test.myopenid.com']
  end

  it "can unmap" do
    RPXNow.map('http://test.myopenid.com', 5)
    User.new.rpx.unmap('http://test.myopenid.com')
    User.new.rpx.identifiers.should == []
  end
end