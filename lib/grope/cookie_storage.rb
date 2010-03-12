require 'uri'

module Grope
  class CookieStorage
    attr_reader :hash

    def initialize
      @hash = {}
      @effective_tld_names = EffectiveTldNames.parse(File.dirname(__FILE__) +
        '/../../data/effective_tld_names.dat')
    end

    def set_cookie(cookie)
      domain = cookie.domain.to_s
      path = cookie.path.to_s
      name = cookie.name.to_s

      if domain =~ /[^\.]+\.((com|edu|net|org|gov|mil|int)|[^\.]+\.[^\.]+)$/ ||
          !@effective_tld_names.match(domain)
        hash[domain] ||= {}
        hash[domain][path] ||= {}
        hash[domain][path][name] = cookie
      else
        nil
      end
    end

    def cookies_for_url(url)
      uri = URI(url)
      cookies = {}
      now = Time.now.to_ns.timeIntervalSince1970

      hash.each do |domain, paths|
        if check_domain(uri.host, domain)
          paths.each do |path, names|
            if check_path(uri.path, path)
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

    def check_domain(domain, cookie_domain)
      domain = (cookie_domain =~ /^\./ ? '.' : '') + domain
      (cookie_domain =~ /^\./) ? domain.rindex(cookie_domain) == (domain.size - cookie_domain.size) :
        domain == cookie_domain
    end

    def check_path(path, cookie_path)
      path_for_compare(path).index(path_for_compare(cookie_path)) == 0
    end

    def path_for_compare(path)
      if path != '/'
        path + '/'
      else
        path
      end
    end
  end
end
