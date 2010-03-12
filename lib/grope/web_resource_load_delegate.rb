module Grope
  class WebResourceLoadDelegate < NSObject
    attr_accessor :cookie_storage

    def webView_resource_willSendRequest_redirectResponse_fromDataSource(webview, resource, request, redirect_response, data_source)
      request.setHTTPShouldHandleCookies(false)

      if redirect_response
        set_cookies(redirect_response)
      end

      cookies = cookie_storage.cookies_for_url(request.URL.to_s)
      if cookies.size > 0
        warn "*** send cookie for %s ***\n%s" % [request.URL.to_s, cookies]
        cookie_fields = NSHTTPCookie.requestHeaderFieldsWithCookies(cookies)
        request.setAllHTTPHeaderFields(cookie_fields)
      end

      request
    end

    def webView_resource_didReceiveResponse_fromDataSource(webview, resource, response, data_source)
      set_cookies(response)
    end

    private

    def set_cookies(response)
      headers = response.allHeaderFields
      url = response.URL

      NSHTTPCookie.cookiesWithResponseHeaderFields_forURL(headers, url).each do |cookie|
        if cookie_storage.set_cookie(cookie)
          warn "*** store cookie for %s ***\n%s" % [response.URL.to_s, cookie]
        end
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

    "%s=%s\t%s\t%s\t%s\n" % [name, value, domain, path, expiresDate]
  end
end
