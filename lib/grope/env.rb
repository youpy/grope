require 'mechanize'

module Grope
  class Env
    def initialize(options = {})
      @options = {
        :timeout => 60,
        :use_shared_cookie => false,
        :init_width => 1024,
        :init_height => 600
      }.merge(options)

      NSApplication.sharedApplication
      @webview = WebView.alloc
      @webview.initWithFrame(rect)
      @webview.setPreferencesIdentifier('Grope')
      @webview.preferences.setShouldPrintBackgrounds(true)
      @webview.preferences.setAllowsAnimatedImages(false)
      @webview.mainFrame.frameView.setAllowsScrolling(false)
      @webview.setMediaStyle('screen')

      create_window

      @frame_load_delegate = FrameLoadDelegate.alloc.init
      @webview.setFrameLoadDelegate(@frame_load_delegate)

      unless @options[:use_shared_cookie]
        @resource_load_delegate = WebResourceLoadDelegate.alloc.init
        @resource_load_delegate.cookie_storage = Mechanize::CookieJar.new
        @webview.setResourceLoadDelegate(@resource_load_delegate)
      end
    end

    def load(url)
      run do
        @webview.setMainFrameURL(url)
        if !@webview.mainFrame.provisionalDataSource && url !~ /^about:/
          raise " ... not a proper url?"
        end
      end
    end

    def eval(js)
      value = nil
      run do
        wso = @webview.windowScriptObject
        value = WSOWrapper.wrap(wso.evaluateWebScript(<<JS % js))
(function() {
  var Grope = {
    click: function(e) { this._dispatchMouseEvent(e, 'click') },
    mouseover: function(e) { this._dispatchMouseEvent(e, 'mouseover') },
    mouseout: function(e) { this._dispatchMouseEvent(e, 'mouseout') },
    mousedown: function(e) { this._dispatchMouseEvent(e, 'mousedown') },
    mouseup: function(e) { this._dispatchMouseEvent(e, 'mouseup') },
    xpath: function(exp, context, type /* want type */) {
      if (typeof context == "function") {
        type = context;
        context = null;
      }
      if (!context) context = document;
      exp = (context.ownerDocument || context).createExpression(exp, function (prefix) {
        var o = document.createNSResolver(context)(prefix);
        if (o) return o;
        return (document.contentType == "application/xhtml+xml") ? "http://www.w3.org/1999/xhtml" : "";
      });

      switch (type) {
      case String: return exp.evaluate(context, XPathResult.STRING_TYPE, null).stringValue;
      case Number: return exp.evaluate(context, XPathResult.NUMBER_TYPE, null).numberValue;
      case Boolean: return exp.evaluate(context, XPathResult.BOOLEAN_TYPE, null).booleanValue;
      case Array:
        var result = exp.evaluate(context, XPathResult.ORDERED_NODE_SNAPSHOT_TYPE, null);
        for (var ret = [], i = 0, len = result.snapshotLength; i < len; i++) {
          ret.push(result.snapshotItem(i));
        }
        return ret;
      case undefined:
        var result = exp.evaluate(context, XPathResult.ANY_TYPE, null);
        switch (result.resultType) {
        case XPathResult.STRING_TYPE : return result.stringValue;
        case XPathResult.NUMBER_TYPE : return result.numberValue;
        case XPathResult.BOOLEAN_TYPE: return result.booleanValue;
        case XPathResult.UNORDERED_NODE_ITERATOR_TYPE:
          // not ensure the order.
          var ret = [], i = null;
          while ((i = result.iterateNext())) ret.push(i);
          return ret;
        }
        return null;
      default: throw(TypeError("$X: specified type is not valid type."));
      }
    },
    getElementPosition: function(elem) {
      var position = elem.getBoundingClientRect();
      return {
        left: Math.round(window.scrollX+position.left),
        top: Math.round(window.scrollY+position.top),
        width: elem.clientWidth,
        height: elem.clientHeight
      }
    },

    _dispatchMouseEvent: function(e, type, dst) {
      var evt = document.createEvent('MouseEvents');
      dst = dst || e;
      var pos = dst.getBoundingClientRect();
      evt.initMouseEvent(type, true, true, window, 0, 0, 0, Math.round(pos.left), Math.round(pos.top), false, false, false, false, 0, null);
      e.dispatchEvent(evt);
    }
  };

  %s
})()
JS
      end
      wait
      value
    end

    def wait(sec = 0)
      run(sec) do; end
    end

    def wait_until(options = {})
      options = {
        :timeout => 10
      }.merge(options)

      start = Time.now.to_i

      begin
        result = yield self

        if result
          return result
        end

        wait(1)
      end until Time.now.to_i >= start + options[:timeout]

      raise TimeoutError
    end

    def document
      eval('return document;')
    end

    def window
      eval('return window;')
    end

    def all(xpath, node = nil)
      node ||= document
      js.xpath(xpath, node)
    end

    def find(xpath, node = nil)
      all(xpath, node)[0]
    end

    def capture(elem = nil, filename = "capture.png")
      view = @webview.mainFrame.frameView.documentView
      bounds = view.bounds

      if elem
        position = js.getElementPosition(elem)

        raise "element's width is 0" if position.width.zero?
        raise "element's height is 0" if position.height.zero?

        bounds.origin.x = position.left
        bounds.origin.y = position.top
        bounds.size.width = position.width
        bounds.size.height = position.height
      end

      wait

      view.display
      view.window.setContentSize(NSUnionRect(view.bounds, bounds).size)
      view.setFrame(NSUnionRect(view.bounds, bounds))

      view.lockFocus
      bitmapdata = NSBitmapImageRep.alloc
      bitmapdata.initWithFocusedViewRect(bounds)
      view.unlockFocus

      bitmapdata.representationUsingType_properties(NSPNGFileType, nil).
        writeToFile_atomically(filename.to_s, 1)
    end

    private

    def run(wait_sec = 0)
      @frame_load_delegate.performSelector_withObject_afterDelay('timeout:', @webview, @options[:timeout])

      result = yield

      run_loop = NSRunLoop.currentRunLoop
      run_loop.runMode_beforeDate(NSDefaultRunLoopMode, Time.now)
      while(@webview.isLoading? && @frame_load_delegate.should_keep_running &&
          run_loop.runMode_beforeDate(NSDefaultRunLoopMode, Time.now + 0.1)); end
      run_loop.runUntilDate(Time.now + wait_sec)

      result
    ensure
      NSObject.cancelPreviousPerformRequestsWithTarget_selector_object(@frame_load_delegate, 'timeout:', @webview)
    end

    def js
      eval('return Grope')
    end

    def create_window
      unless @window
        @window = NSWindow.alloc.initWithContentRect_styleMask_backing_defer_(rect, NSBorderlessWindowMask, 2, false)
        @window.setContentView(@webview)
      end
    end

    def rect
      NSMakeRect(0,0,@options[:init_width],@options[:init_height])
    end
  end
end
