#encoding: utf-8
module SpreeProductsImporter
  module Parsers
    class DateTimeParser
       def initialize format="%d/%m/%y"
        @format = format
      end

      def parse value
        DateTime.strptime(value, @format).to_s
      end
    end
  end
end
