[
  DOMNodeList,
  DOMHTMLOptionsCollection,
  DOMHTMLCollection
].each do |klass|
  klass.class_eval do
    def [](index)
      item(index)
    end
  end
end

class WebScriptObject
  def [](index)
    webScriptValueAtIndex(index)
  end
end
