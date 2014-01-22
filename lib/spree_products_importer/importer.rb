#encoding: utf-8
require 'roo'

module SpreeProductsImporter

  class Handler

    # Receives a file and the get data from each file row
    def self.get_file_data(file)
      spreadsheet = open_spreadsheet(file)
      header = spreadsheet.row(1)
      (2..spreadsheet.last_row).each do |i|
        row = Hash[[header, spreadsheet.row(i)].transpose]
        puts row.inspect

        # product = find_by_id(row["id"]) || new
        # product.attributes = row.to_hash.slice(*accessible_attributes)
        # product.save!
      end
    end
      
    # Receives a file and then returns a Roo object acording the file extension
    def self.open_spreadsheet(file)
      case File.extname(file.original_filename)
      when '.csv' then Roo::Csv.new(file.path, nil, :ignore)
      when '.xls' then Roo::Excel.new(file.path, nil, :ignore)
      when '.xlsx' then Roo::Excelx.new(file.path, nil, :ignore)
      else raise "Unknown file type: #{file.original_filename}"
      end
    end

  end

end