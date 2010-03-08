require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe Grope::Env do
  it "should initialize" do
    env = Grope::Env.open('http://example.com')
    env.document.title.should eql('Example Web Page')
  end

  it "should initialize within a block" do
    result = Grope::Env.open('http://example.com') do |env|
      document = env.document
      document.getElementsByTagName('a')[0].href.to_s
    end

    result.should eql('http://www.rfc-editor.org/rfc/rfc2606.txt')
  end

  it "should get elements by XPath" do
    result = Grope::Env.open('http://example.com') do |env|
      env.xpath('//a')
    end

    result.size.should eql(1)
    result[0].href.to_s.should eql('http://www.rfc-editor.org/rfc/rfc2606.txt')
  end

  it "should eval" do
    env = Grope::Env.open('http://example.com')
    env.eval('return window').location.href.should eql('http://example.com/')
  end
end
