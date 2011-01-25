module Grope
  class FrameLoadDelegate < NSObject
    attr_accessor :should_keep_running

    def webView_didFailLoadWithError_forFrame(webview, error, frame)
      terminate
    end
    alias webView_didFailProvisionalLoadWithError_forFrame webView_didFailLoadWithError_forFrame

    def webView_didStartProvisionalLoadForFrame(webview, frame)
      self.should_keep_running = true
    end

    def webView_willPerformClientRedirectToURL_delay_fireDate_forFrame(webview, url, delay, date, frame)
      self.should_keep_running = true
    end

    def webView_didFinishLoadForFrame(webview, frame)
      if frame == webview.mainFrame
        terminate
      end
    end

    def terminate
      self.should_keep_running = false
    end

    def timeout(webview)
      warn "timeout"
      terminate
    end
  end
end
