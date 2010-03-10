require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Grope::WSOWrapper do
  it "should wrap" do
    WSOWrapper.wrap(nil).should eql(nil)
    WSOWrapper.wrap(true.to_ns).should eql(true)
    WSOWrapper.wrap(false.to_ns).should eql(false)
    WSOWrapper.wrap(1.to_ns).should eql(1)
    WSOWrapper.wrap("a".to_ns).should eql("a")
  end
end
