module Grope
  class WSOWrapper
    instance_methods.each do |m|
      undef_method m unless m.to_s =~
        /inspect|to_s|class|method_missing|respond_to?|^__/
    end

    include Enumerable

    attr_reader :wso

    def self.wrap(value)
      case value
      when nil
        nil
      when WSOWrapper
        value
      when Integer
        value
      when OSX::NSCFBoolean
        value.boolValue
      when OSX::NSCFNumber
        value.integer? ? value.to_i : value.to_f
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

    def each
      i = 0
      while i < size
        yield self[i]
        i += 1
      end
    end

    def method_missing(name, *args)
      args = unwrap_arguments(args)
      result = nil

      begin
        if name.to_s =~ /^(apply|call|toString)$/
          result = @wso.callWebScriptMethod_withArguments(name, args)
        else
          result = @wso.__send__(name, *args)
        end
      rescue 
        result = @wso.valueForKey(name)
      end

      if WebScriptObject === result &&
          result.callWebScriptMethod_withArguments(:toString, []).to_s =~ /^function/
        self.class.wrap(result.callWebScriptMethod_withArguments(:call, [@wso] + args))
      else
        self.class.wrap(result)
      end
    end

    private

    def unwrap_arguments(args)
      args.map do |arg|
        self.class === arg ? arg.wso : arg
      end
    end
  end
end
