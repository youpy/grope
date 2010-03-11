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
        warn 'send cookie for %s' % request.URL.to_s
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
        warn 'store cookie for %s' % response.URL.to_s
        cookie_storage.set_cookie(cookie)
      end
    end
  end
end
