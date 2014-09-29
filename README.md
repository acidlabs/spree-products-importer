SpreeProductsImporter
=====================

Import tool for Spree Product.

Installation
------------

Add spree_products_importer to your Gemfile:

```ruby
gem 'spree_products_importer'
```

Bundle your dependencies and run the installation generator:

```shell
bundle
bundle exec rails g spree_products_importer:install
```




Uso
---

Usted debe definir un decorador del SpreeProductsImporter::Importer, y debera crear un inicializador que como el siguiente:

```ruby
module SpreeProductsImporter
  Importer.class_eval do
    def initialize filename, filepath
      @filename = filename
      @filepath = filepath

      @spreadsheet = nil

      @product_identifier = ProductIdentifier.new('A', :name)

      @mappers = []
      @mappers << Mappers::ProductMapper.new('A', :name)
      @mappers << Mappers::ProductMapper.new('B', :sku)
      @mappers << Mappers::ProductMapper.new('C', :prototype_id)
      @mappers << Mappers::ProductMapper.new('D', :price)
      @mappers << Mappers::ProductMapper.new('E', :available_on)
      @mappers << Mappers::ProductMapper.new('F', :shipping_category_id)
    end
  end
end
```

* En este se define el archivo a leer
* Una variable para almacenar el los datos del archivo
* Una instancia de la clase que permite verificar el el producto existe
* Un arreglo con instancia de que heredan de la clase Mappers::BaseMapper

La logica se base en diferentes `Mappers` un mapper esta encargado de mapear el resultado de una columna un alguno de los
modelo de spree, por tanto un mapper requiere para funcionar,

1.- La columna que va a mappear
2.- Nombre del attributo en el modelo que esta mapeando
3.- (Opcional) de forma opcional, es posible proporcionar al constructor del mapper un parametros de una clase esecializada
para formatear la data segun se requiera, lo unico importante es que esta clase responda con el metodo de clase `parse` y como
parametro el valor que se requiere formatear.

De esta forma usted tiene una columna available_on con formato `9/7/14 0:00`, usted puede definir si importer de la siguiente forma:

```ruby
module SpreeProductsImporter
  class DateTimeParser
    def self.parse value
      DateTime.strptime(value, "%d/%m/%y").to_s
    end
  end
end

module SpreeProductsImporter
  Importer.class_eval do
    def initialize filename, filepath
      ...
      @mappers << Mappers::ProductMapper.new('E', :available_on, DateTimeParser))
      ...
    end
  end
end
```






Testing
-------

Be sure to bundle your dependencies and then create a dummy test app for the specs to run against.

```shell
bundle
bundle exec rake test_app
bundle exec rspec spec
```

When testing your applications integration with this extension you may use it's factories.
Simply add this require statement to your spec_helper:

```ruby
require 'spree_products_importer/factories'
```

Copyright (c) 2014 [Acid Labs](http://acid.cl), all rigths reserved.
