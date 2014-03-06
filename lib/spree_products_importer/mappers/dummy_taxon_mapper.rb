#encoding: utf-8
module SpreeProductsImporter
  module Mappers
    class DummyTaxonMapper < SpreeProductsImporter::Mappers::BaseMapper
      # Indicates that the field is stored in the data Hash for a Taxonomy
      #
      # Returns an Symbol
      def self.data
        :product
      end

      def self.make_ids_array value
        if Mappers::BaseMapper.make_ids_array(value).include?('1')
          if Spree::Taxon.exists?({name: 'Dummie'})
            [Spree::Taxon.find_by({name: 'Dummie'}).id]
          else
            taxonomy = Spree::Taxonomy.find_or_create_by_name('Dummie')
            root     = taxonomy.root
            taxon    = Spree::Taxon.create! name: 'Dummie', taxonomy: taxonomy, parent: root, position: taxonomy.taxons.count

            [taxon.id]
          end
        else
          []
        end
      end
    end
  end
end