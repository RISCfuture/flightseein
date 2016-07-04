class CreateAirports < ActiveRecord::Migration[4.2]
  def up
    execute <<-SQL
      CREATE TABLE airports (
        id SERIAL PRIMARY KEY,
        metadata_id INTEGER REFERENCES metadata(id) ON DELETE CASCADE,
        site_number CHARACTER VARYING(11) NOT NULL UNIQUE,
        lid CHARACTER VARYING(4) CHECK (CHAR_LENGTH(lid) > 0),
        icao CHARACTER VARYING(4) CHECK (CHAR_LENGTH(icao) > 0),
        iata CHARACTER VARYING(4) CHECK (CHAR_LENGTH(iata) > 0),
        CHECK (lid IS NOT NULL OR icao IS NOT NULL OR iata IS NOT NULL)
      )
    SQL

    execute "CREATE UNIQUE INDEX airports_ident ON airports(lid, icao, iata)"
    execute "CREATE INDEX airports_lid ON airports(lid)"
    execute "CREATE INDEX airports_icao ON airports(icao)"
    execute "CREATE INDEX airports_iata ON airports(iata)"
  end

  def down
    drop_table :airports
  end
end
