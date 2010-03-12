module Grope
  class WebResourceLoadDelegate < NSObject
    attr_accessor :cookie_storage

    def webView_resource_willSendRequest_redirectResponse_fromDataSource(webview, resource, request, redirect_response, data_source)
      request.setHTTPShouldHandleCookies(false)

      if request.URL.to_s =~ /^http/
        if redirect_response
          set_cookies(redirect_response)
        end

        cookies = cookie_storage.cookies(URI(request.URL.to_s))
        if cookies.size > 0
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
        cookie_storage.add(URI(url.to_s), cookie)
      end
    end
  end
end

class NSHTTPCookie
  def expires
    Time.at(expiresDate.timeIntervalSince1970.to_i)
  end
end
