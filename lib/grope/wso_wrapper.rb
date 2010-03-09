module Grope
  class WSOWrapper
    instance_methods.each do |m|
      undef_method m unless m.to_s =~
        /inspect|to_s|class|method_missing|respond_to?|^__/
    end

    include Enumerable

    def self.wrap(value)
      case value
      when WSOWrapper
        value
      when Integer
        value
      when OSX::NSCFNumber
        value.to_i
      when OSX::NSCFString
        value.to_s
      else
        new(value)
      end
    end

    def initialize(wso)
      @wso = wso
    end

    def size
      length
    end

    def [](index)
      self.class.wrap(@wso[index])
    rescue
      webScriptValueAtIndex(index)
    end

    def each
      i = 0
      while i < size
        yield self.class.wrap(self[i])
        i += 1
      end
    end

    def method_missing(name, *args)
      result = nil
      begin
        result = @wso.send(name, *args)
      rescue 
        result = @wso.valueForKey(name)
      end

      self.class.wrap(result)
    end
  end
end
