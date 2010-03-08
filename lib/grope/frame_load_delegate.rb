module Grope
  class FrameLoadDelegate < NSObject
    attr_accessor :callback
    attr_accessor :should_keep_running
    attr_reader :last_result

    def webView_didFailLoadWithError_forFrame(webview, error, frame)
      raise "failed to load: %s" % error.to_s
    ensure
      terminate
    end
    alias webView_didFailProvisionalLoadWithError_forFrame webView_didFailLoadWithError_forFrame

    def webView_didFinishLoadForFrame(webview, frame)
      @last_result = callback.call(Env.new(webview))
    ensure
      terminate
    end

    def getURL(url, webview)
      webview.mainFrame.loadRequest(NSURLRequest.requestWithURL(NSURL.URLWithString(url)))
      if !webview.mainFrame.provisionalDataSource
        raise " ... not a proper url?"
      end
    ensure
      terminate
    end

    def terminate
      self.should_keep_running = false
    end

    def timeout(obj)
      raise 'timeout'
    ensure
      terminate
    end
  end
end
