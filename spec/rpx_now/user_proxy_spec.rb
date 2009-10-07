require 'spec/spec_helper'

class User
  include RPXNow::UserIntegration

  def id
    5
  end
end

describe RPXNow::UserProxy do
  before { @user = User.new }

  it "should create a proxy" do
    RPXNow::UserProxy.expects(:new).with(@user.id).returns('proxy')
    @user.rpx.should == 'proxy'
  end

  it "has identifiers" do
    RPXNow.expects(:mappings).with(@user.id).returns('identifiers')
    @user.rpx.identifiers.should == 'identifiers'
  end

  it "can map" do
    RPXNow.expects(:map).with('identifier', @user.id).returns('new_mapping')
    @user.rpx.map('identifier').should == 'new_mapping'
  end

  it "can unmap" do
    RPXNow.expects(:unmap).with('identifier', @user.id)
    @user.rpx.unmap('identifier')
  end
end