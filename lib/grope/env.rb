module Grope
  class Env
    def initialize(options = {})
      @options = {
        :timeout => 60,
        :use_shared_cookie => false,
      }.merge(options)

      @webview = WebView.alloc
      @webview.initWithFrame(NSMakeRect(0,0,100,100))
      @webview.setPreferencesIdentifier('Grope')
      @frame_load_delegate = FrameLoadDelegate.alloc.init
      @webview.setFrameLoadDelegate(@frame_load_delegate)

      unless @options[:use_shared_cookie]
        @resource_load_delegate = WebResourceLoadDelegate.alloc.init
        @resource_load_delegate.cookie_storage = CookieStorage.new
        @webview.setResourceLoadDelegate(@resource_load_delegate)
      end
    end

    def load(url)
      run do
        @webview.setMainFrameURL(url)
        if !@webview.mainFrame.provisionalDataSource
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

    _dispatchMouseEvent: function(e, type) {
      var evt = document.createEvent('MouseEvents');
      evt.initMouseEvent(type, true, true, window, 0, 0, 0, 0, 0, false, false, false, false, 0, null);
      e.dispatchEvent(evt);
    },
  }

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

    def document
      eval('return document;')
    end

    def window
      eval('return window;')
    end

    def xpath(xpath)
      eval(script_for_xpath % xpath.gsub(/"/, '\"'))
    end

    private

    def run(wait_sec = 0)
      @frame_load_delegate.performSelector_withObject_afterDelay('timeout:', @webview, @options[:timeout])

      result = yield

      run_loop = NSRunLoop.currentRunLoop
      run_loop.runMode_beforeDate(NSDefaultRunLoopMode, Time.now)
      while(@frame_load_delegate.should_keep_running &&
          run_loop.runMode_beforeDate(NSDefaultRunLoopMode, Time.now + 0.1)); end
      run_loop.runMode_beforeDate(NSDefaultRunLoopMode, Time.now + wait_sec)

      result
    ensure
      NSObject.cancelPreviousPerformRequestsWithTarget_selector_object(@frame_load_delegate, 'timeout:', @webview)
    end

    def script_for_xpath
      <<JS
return (function(exp, context, type /* want type */) {
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
})("%s");
JS
    end
  end
end
