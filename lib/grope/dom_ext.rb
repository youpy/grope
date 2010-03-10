class DOMNodeList
  def [](index)
    item(index)
  end
end

class DOMHTMLCollection
  def [](index)
    item(index)
  end
end

class WebScriptObject
  def [](index)
    webScriptValueAtIndex(index)
  end
end
