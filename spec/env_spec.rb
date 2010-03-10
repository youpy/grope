require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Grope::Env do
  before do
    @env = Grope::Env.new
    @env.load('http://example.com')
  end

  it "should initialize" do
    @env.document.title.should eql('Example Web Page')
  end

  it "should get elements by XPath" do
    result = @env.xpath('//a')
    result.size.should eql(1)
    result[0].href.should eql('http://www.rfc-editor.org/rfc/rfc2606.txt')
  end

  it "should eval" do
    @env.eval('return window').location.href.should eql('http://example.com/')
  end

  it "should redirect" do
    @env.eval('location.href="http://example.org"')
    @env.document.location.href.should eql('http://example.org/')
  end

  it "should redirect by click" do
    @env.eval('click(document.getElementsByTagName("a")[0])')
    @env.document.location.href.should eql('http://www.rfc-editor.org/rfc/rfc2606.txt')
  end
end
