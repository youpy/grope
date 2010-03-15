module Grope
  class WebResourceLoadDelegate < NSObject
    attr_accessor :cookie_storage

    def webView_resource_willSendRequest_redirectResponse_fromDataSource(webview, resource, request, redirect_response, data_source)
      request.setHTTPShouldHandleCookies(false)

      if request.URL.to_s =~ /^http/
        if redirect_response
          set_cookies(redirect_response)
        end

        cookies = cookie_storage.cookies(URI(request.URL.to_s)).map {|wrapper| wrapper.cookie}
        if cookies.size > 0
          #warn "*** send cookie for %s ***\n%s" % [request.URL.to_s, cookies]
          cookie_fields = NSHTTPCookie.requestHeaderFieldsWithCookies(cookies)
          request.setAllHTTPHeaderFields(cookie_fields)
        end
      end

      request
    end

    def webView_resource_didReceiveResponse_fromDataSource(webview, resource, response, data_source)
      set_cookies(response)
    end

    private

    def set_cookies(response)
      return unless response.isKindOfClass(NSHTTPURLResponse)

      headers = response.allHeaderFields
      url = response.URL

      NSHTTPCookie.cookiesWithResponseHeaderFields_forURL(headers, url).each do |cookie|
        cookie_storage.add(URI(url.to_s), NSHTTPCookieWrapper.new(cookie))
        #warn "*** store cookie for %s ***\n%s" % [response.URL.to_s, cookie]
      end
    end
  end
end

class NSHTTPCookie
  def to_s
    value = self.value
    if value.size > 50
      value = value[0, 47] + '...'
    end

    "%s=%s\t%s\t%s\t%s\n" % [name, value, domain, path, expiresDate, isSecure]
  end
end

class NSHTTPCookieWrapper
  attr_reader :cookie

  def initialize(cookie)
    @cookie = cookie
  end

  def domain
    cookie.domain && cookie.domain.to_s.sub(/^\./, '')
  end

  def path
    cookie.path && cookie.path.to_s
  end

  def name
    cookie.name.to_s
  end

  def value
    cookie.value
  end

  def secure
    cookie.isSecure == true.to_ns ? true : false
  end

  def expired?
    cookie.expiresDate && Time.at(cookie.expiresDate.timeIntervalSince1970.to_i)
  end
end
