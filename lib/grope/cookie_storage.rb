require 'uri'

module Grope
  class CookieStorage
    attr_reader :hash

    def initialize
      @hash = {}
    end

    def set_cookie(cookie)
      domain = cookie.domain.to_s
      path = cookie.path.to_s
      name = cookie.name.to_s

      hash[domain] ||= {}
      hash[domain][path] ||= {}
      hash[domain][path][name] = cookie
    end

    def cookies_for_url(url)
      uri = URI(url)
      cookies = {}
      now = Time.now.to_ns.timeIntervalSince1970

      hash.each do |domain, paths|
        host = (domain =~ /\./ ? '.' : '') + uri.host
        if host.rindex(domain) == (host.size - domain.size)
          paths.each do |path, names|
            if path_for_compare(uri.path).index(path_for_compare(path)) == 0
              names.each do |name, cookie|
                next unless cookie
                if !cookie.expiresDate || cookie.expiresDate.timeIntervalSince1970 > now
                  unless cookie.isSecure && uri.scheme != 'https'
                    cookies[name] ||= {}
                    cookies[name][path] = cookie
                  end
                else
                  hash[domain][path][name] = nil
                end
              end
            end
          end
        end
      end

      cookies.inject([]) do |memo, v|
        name, paths = v
        paths.each do |path, cookie|
          ok = true
          paths.each do |p, v|
            if p != path && p.index(path)
              ok = false
              break
            end
          end

          if ok
            memo << cookie
          end
        end

        memo
      end
    end

    private

    def path_for_compare(path)
      if path != '/'
        path + '/'
      else
        path
      end
    end
  end
end
