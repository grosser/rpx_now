require 'spec/spec_helper'
require 'rpx_now/user_integration'

class User
  include RPXNow::UserIntegration

  def id
    5
  end
end

describe RPXNow::UserProxy do
  before { @user = User.new }

  it "has a proxy" do
    @user.rpx.class.should == RPXNow::UserProxy
  end

  it "has identifiers" do
    RPXNow.should_receive(:mappings).with(@user.id).and_return(['identifiers'])
    @user.rpx.identifiers.should == ['identifiers']
  end

  it "can map" do
    RPXNow.should_receive(:map).with('identifier', @user.id)
    @user.rpx.map('identifier')
  end

  it "can unmap" do
    RPXNow.should_receive(:unmap).with('identifier', @user.id)
    @user.rpx.unmap('identifier')
  end
end