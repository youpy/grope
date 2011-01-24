require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

require 'pathname'
require 'shellwords'

describe Grope::Env do
  before(:all) do
    @env = Grope::Env.new
    @env.load('http://example.com')
  end

  it "should initialize" do
    @env.document.title.should eql('Example Web Page')
  end

  it "should get elements by XPath" do
    body = @env.find('//body')
    @env.find('//a', body).href.should eql('http://www.rfc-editor.org/rfc/rfc2606.txt')
    @env.all('//a', body)[0].href.should eql('http://www.rfc-editor.org/rfc/rfc2606.txt')
  end

  it "should get links" do
    result = @env.document.links
    result[0].href.should eql('http://www.rfc-editor.org/rfc/rfc2606.txt')
  end

  it "should eval" do
    @env.window.location.href.should eql('http://example.com/')
  end

  it "should redirect" do
    @env.eval('location.href="http://example.org"')
    @env.document.location.href.should eql('http://example.org/')
  end

  it "should redirect by click" do
    anchor = @env.document.links[0]
    js = @env.eval('return Grope;')
    js.click(anchor)

    # TODO: wait automatically after js function is called
    @env.wait

    @env.document.URL.should eql('http://www.rfc-editor.org/rfc/rfc2606.txt')
  end

  it "should get/call function" do
    function = @env.eval('return function(x, y) { return x * y }')
    function.call(false, 3, 5).should eql(15)
    function.apply(false, [3, 5]).should eql(15)
  end

  it "should call function in object" do
    obj = @env.eval('return { hello: function() { return "hello"; }}')
    obj.hello.should eql('hello')
  end

  it "should wait" do
    now = Time.now.to_i

    @env.wait(3)

    (Time.now.to_i - now).should be_close(3, 1)
  end

  it "should use shared cookie storage if 'use_shared_cookie' option is true" do
    env = Grope::Env.new(:use_shared_cookie => true)
    env.instance_eval { @resource_load_delegate }.should be_nil
  end

  it "should use own cookie storage if 'use_shared_cookie' option is false" do
    @env.instance_eval { @resource_load_delegate }.should_not be_nil
    @env.load('http://google.com/')
    @env.instance_eval { @resource_load_delegate }.cookie_storage.cookies(URI('http://google.com/')).should_not be_nil
  end

  describe "#capture" do
    before do
      dir = Pathname(Dir.tmpdir)
      @filename = dir + 'test.png'
    end

    after do
      if @filename.file?
        @filename.unlink
      end
    end

    it "should capture specified element and write to file as png" do
      pending "it causes segmentation fault"
      element = @env.find('//p')

      @env.capture(element, @filename)

      info = `file #{Shellwords.shellescape(@filename.to_s)}`

      info.should match(/PNG image/)

      width, height = info.scan(/(\d+) x (\d+)/)[0]

      width.to_i.should eql(element.clientWidth)
      height.to_i.should eql(element.clientHeight)
    end

    it "should capture whole content" do
      @env.capture(nil, @filename)

      info = `file #{Shellwords.shellescape(@filename.to_s)}`

      info.should match(/PNG image/)

      width, height = info.scan(/(\d+) x (\d+)/)[0]

      width.to_i.should eql(1024)
      height.to_i.should eql(600)
    end

    it "should raise error if width(or height) of specified element is zero" do
      lambda {
        element = @env.find('//a')
        @env.capture(element, @filename)
      }.should raise_error(RuntimeError)
    end
  end
end
