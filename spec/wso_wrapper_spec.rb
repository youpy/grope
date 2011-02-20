require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Grope::WSOWrapper do
  it "should wrap" do
    Grope::WSOWrapper.wrap(nil).should eql(nil)
    Grope::WSOWrapper.wrap(true.to_ns).should eql(true)
    Grope::WSOWrapper.wrap(false.to_ns).should eql(false)
    Grope::WSOWrapper.wrap(1.to_ns).should eql(1)
    Grope::WSOWrapper.wrap("a".to_ns).should eql("a")
  end
end
