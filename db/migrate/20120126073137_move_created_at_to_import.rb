class MoveCreatedAtToImport < ActiveRecord::Migration
  def up
    execute "ALTER TABLE imports ADD created_at TIMESTAMP WITHOUT TIME ZONE"
    Import.reset_column_information
    Import.includes(:metadata).find_each do |i|
      i.send :write_attribute, :created_at, i.metadata.data[:created_at]
      i.save!
    end
  end

  def down
    Import.includes(:metadata).find_each do |i|
      i.metadata.data = i.metadata.data.merge(created_at: i.created_at)
      i.metadata.save!
    end
    execute "ALTER TABLE imports REMOVE created_at"
  end
end
