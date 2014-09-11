#encoding: utf-8
module SpreeProductsImporter
  module Parsers
    class ArrayParser
      def initialize splitter=','
        @splitter = splitter
      end

      def parse value
        value.split(@splitter)
      end
    end
  end
end
