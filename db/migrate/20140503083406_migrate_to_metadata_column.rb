class MigrateToMetadataColumn < ActiveRecord::Migration
  MODELS = [Airport, User, Aircraft, Destination, Person, Flight, Photograph, Import]

  def up
    MODELS.each do |model|
      add_column model.table_name, :metadata, :text
      model.reset_column_information

      model.find_in_batches do |records|
        metadatas = select_rows("SELECT id, data FROM metadata WHERE id IN (#{records.map(&:metadata_id).join(',')})").inject({}) do |hsh, (id, data)|
          hsh[id.to_i] = YAML.load(data)
          hsh
        end
        records.each { |record| record.update_column :metadata, metadatas[record.metadata_id].to_json }
      end

      remove_column model.table_name, :metadata_id
    end

    drop_table :metadata
  end

  def down
    MODELS.each do |model|
      execute "ALTER TABLE #{model.quoted_table_name} ADD COLUMN metadata_id INTEGER REFERENCES metadata(id) ON DELETE CASCADE"
      model.reset_column_information

      model.find_each do |record|
        metadata = Metadata.create!(data: record._metadata_hash)
        record.update_attribute :metadata_id, metadata.id
      end

      remove_column model.table_name, :metadata
    end

    create_table :metadata
  end
end
