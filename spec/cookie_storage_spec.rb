require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'date'

class DummyCookie
  attr_accessor :domain, :comment, :commentURL, :expiresDate, :isHTTPOnly, :isSecure, :isSessionOnly, :name, :path, :portList, :properties, :value, :version
end

describe Grope::CookieStorage do
  before do
    @storage = Grope::CookieStorage.new
    @cookie = create_cookie
  end

  describe '#set_cookie' do
    it "should set cookie" do
      @storage.set_cookie(@cookie)

      @storage.hash['.google.com']['/']['foo'].should eql(@cookie)

      @cookie.name = 'bar'
      @storage.set_cookie(@cookie)

      @storage.hash['.google.com']['/']['bar'].should eql(@cookie)

      @cookie.path = '/foo/bar'
      @storage.set_cookie(@cookie)

      @storage.hash['.google.com']['/foo/bar']['bar'].should eql(@cookie)

      @cookie.domain = '.twitter.com'
      @storage.set_cookie(@cookie)

      @storage.hash['.twitter.com']['/foo/bar']['bar'].should eql(@cookie)
    end
  end


  describe '#cookies_for_url' do
    it "should get cookies for url" do
      @storage.set_cookie(@cookie)

      @storage.cookies_for_url('http://google.com/').should eql([@cookie])
      @storage.cookies_for_url('http://google.com/foo').should eql([@cookie])
    end

    it "should not get expired cookie" do
      @cookie.expiresDate = (Time.now - 60).to_ns
      @storage.set_cookie(@cookie)

      @storage.cookies_for_url('http://google.com/').should eql([])
    end

    it "should not get secure cookie with http" do
      @cookie.isSecure = true
      @storage.set_cookie(@cookie)

      @storage.cookies_for_url('http://google.com/').should eql([])
      @storage.cookies_for_url('https://google.com/').should eql([@cookie])
    end

    it "should not get with wrong path" do
      @cookie.path = '/foo'
      @storage.set_cookie(@cookie)

      @storage.cookies_for_url('http://google.com/').should eql([])
      @storage.cookies_for_url('http://google.com/fooo').should eql([])
    end

    it "should get cookie with shorter path" do
      @cookie.path = '/foo'
      @storage.set_cookie(@cookie)

      cookie_with_longer_path = create_cookie
      cookie_with_longer_path.path = '/foo/bar'
      @storage.set_cookie(cookie_with_longer_path)

      cookie_with_another_root = create_cookie
      cookie_with_another_root.path = '/bar'
      @storage.set_cookie(cookie_with_another_root)

      @storage.cookies_for_url('http://google.com/foo/bar/baz').should eql([cookie_with_longer_path])
      @storage.cookies_for_url('http://google.com/foo/baz').should eql([@cookie])
      @storage.cookies_for_url('http://google.com/bar').should eql([cookie_with_another_root])
    end
  end

  def create_cookie
    cookie = DummyCookie.new
    cookie.domain = '.google.com'
    cookie.name = 'foo'
    cookie.value = 'xxx'
    cookie.path = '/'
    cookie.isSecure = false
    cookie.expiresDate = (Time.now + 60).to_ns

    cookie
  end
end

