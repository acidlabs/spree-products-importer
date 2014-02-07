#encoding: utf-8
module SpreeProductsImporter
  module Mappers
    class SizeOptionValueMapper < SpreeProductsImporter::Mappers::BaseMapper
      # Indicates that the field is stored in the data Hash for a Product
      #
      # Returns an Symbol
      def self.data
        :variant
      end

      def self.make_ids_array value
        Mappers::BaseMapper.make_ids_array(value).map do |name|
          if Spree::OptionValue.exists?({name: name})
            Spree::OptionValue.find_by({name: name}).id
          else
            ot = Spree::OptionType.find_or_create_by_name('tshirt-size', presentation: 'Size')
            ov = Spree::OptionValue.create! name: name, presentation: name, position: ot.option_values.count + 1, option_type_id: ot.id

            ov.id
          end
        end
      end
    end
  end
end