require 'spec/spec_helper'

describe RPXNow do
  describe :mapping_integration do
    before do
      @k1 = 'http://test.myopenid.com'
      RPXNow.unmap(@k1, 1)
      @k2 = 'http://test-2.myopenid.com'
      RPXNow.unmap(@k2, 1)
    end

    it "has no mappings when nothing was mapped" do
      RPXNow.mappings(1).should == []
    end

    it "unmaps mapped keys" do
      RPXNow.map(@k2, 1)
      RPXNow.unmap(@k2, 1)
      RPXNow.mappings(1).should == []
    end

    it "maps keys to a primary key and then retrieves them" do
      RPXNow.map(@k1, 1)
      RPXNow.map(@k2, 1)
      RPXNow.mappings(1).sort.should == [@k2,@k1]
    end

    it "does not add duplicate mappings" do
      RPXNow.map(@k1, 1)
      RPXNow.map(@k1, 1)
      RPXNow.mappings(1).should == [@k1]
    end

    it "finds all mappings" do
      RPXNow.map(@k1, 1)
      RPXNow.map(@k2, 2)
      RPXNow.all_mappings.sort.should == [["1", ["http://test.myopenid.com"]], ["2", ["http://test-2.myopenid.com"]]]
    end
  end
end