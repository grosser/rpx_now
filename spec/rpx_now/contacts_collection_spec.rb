require 'spec/spec_helper'

describe RPXNow::ContactsCollection do
  before do
    data = JSON.parse(File.read('spec/fixtures/get_contacts_response.json'))['response']
    @collection = RPXNow::ContactsCollection.new(data)
  end

  it "behaves like an array" do
    @collection.size.should == 5
    @collection[0] = "1"
    @collection[0].should == "1"
  end

  it "parses entry to items" do
    @collection[0]['displayName'].should == "Bob Johnson"
  end

  it "parses emails to list" do
    @collection[0]['emails'].should == ["bob@example.com"]
  end

  it "parses emails to list with multiple emails" do
    @collection[2]['emails'].should == ["fred.williams@example.com","fred@example.com"]
  end

  it "holds additional_info" do
    @collection.additional_info['startIndex'].should == 1
    @collection.additional_info['itemsPerPage'].should == 5
    @collection.additional_info['totalResults'].should == 5
  end
end