module Grope
  # ref. http://xcatsan.blogspot.com/2009/09/nshttpcookiestorage-8.html
  class EffectiveTldNames
    attr_accessor :names, :wildcard_names, :exception_names

    def initialize(names, wildcard_names, exception_names)
      @names = names
      @wildcard_names = wildcard_names
      @exception_names = exception_names
    end

    def match(domain)
      if domain.index('.') == 0
        domain = domain[1..-1]
      end

      return true if names.include?(domain)
      return false if exception_names.include?(domain)
      return true if wildcard_names.include?(domain)
      return true if wildcard_names.include?(domain[domain.index('.')+1..-1])

      false
    end

    class << self
      def parse(filename)
        new *extract_names(open(filename).read)
      end

      def extract_names(data)
        names = []
        wildcard_names = []
        exception_names = []

        data.each do |line|
          line.chomp!
          next if line =~ /^[\s|\/]/

          case line
          when /^\*/
            wildcard_names << line[2..-1]
          when /^!/
            exception_names << line[1..-1]
          else
            names << line
          end
        end

        [names, wildcard_names, exception_names]
      end
    end
  end
end
