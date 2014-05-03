# This class converts records in a NASR FADDS distribution file into {Airport}
# records. It is used by the `import:nasr` Rake task.

class AirportImporter
  # @return [Pathname] The NASR text file to import.
  attr_accessor :path

  # Creates a new importer.
  #
  # @param [String] path The directory with the NASR files to import.

  def initialize(path)
    self.path = File.join(File.expand_path(path), 'APT.txt')
  end

  # Performs the import.

  def import
    File.open(path) do |f|
      f.each_line do |line|
        begin
          type = line[0,3]
          if parser = self.class.parser(type) then
            parser.instance.line line
          end
        rescue
          $stderr.puts line
          raise
        end
      end
    end
  end

  protected

  class << self
    # @private
    def parser(type)
      return nil unless parsers.include?("AirportImporter::#{type}Parser")
      AirportImporter.const_get(:"#{type}Parser")
    end

    # @private
    def parsers
      @parsers ||= LineParser.descendants.map(&:to_s)
    end
  end

  private

  # @private
  class LineParser
    include Singleton

    protected

    def parse_line(line)
      self.class.format.inject({}) do |attrs, (name, data)|
        next(attrs) if [ :record_type ].include?(name)

        value = line[data[:range].first - 1, data[:range].last]
        value.strip!
        if value.empty? then
          attrs[name] = nil
        else
          value = send(:"parse_#{data[:parser]}", value) if data[:parser]
          attrs[name] = value
        end
        attrs
      end
    end

    def parse_date(string)
      matches = /^(\d{2}\/\d{2}\/\d{4})$/.match(string)
      raise "Invalid date #{string}" unless matches
      return Date.civil(matchesp3.to_i, matches[1].to_i, matches[2].to_i)
    end

    def parse_angular_distance(string)
      matches = /^(\d{6}\.\d{4})([NSEW])$/.match(string)
      raise "Invalid angular distance #{string}" unless matches
      dist = matches[1].to_f
      dist = -dist if %w( S W ).include?(matches[2])
      return dist/(60*60)
    end
  end

  # @private
  class APTParser < LineParser
    INVALID_STATES = %w( WQ TQ PS MQ IQ CZ CQ CN )

    def self.format
      {
        record_type: { range: [1,3] },
        site_number: { range: [4,11] },
        lid: { range: [28,4] },
        state: { range: [49,2] },
        city: { range: [94,40] },
        name: { range: [134,42] },
        lat: { range: [539,12], parser: :angular_distance },
        lon: { range: [566,12], parser: :angular_distance },
        icao: { range: [1211,7] }
      }
    end

    def line(line)
      attributes = parse_line(line)
      begin
        build_airport attributes
      rescue ActiveRecord::RecordInvalid => err
        $stderr.puts err.record.inspect
        raise
      end
    end

    private

    def build_airport(attributes)
      return if INVALID_STATES.include?(attributes[:state])

      @airports ||= Hash.new
      @airports[attributes[:site_number]] = map_attributes(attributes)

      if @airports.size >= 100 then
        Airport.where(site_number: @airports.keys).each do |airport|
          airport.update_attributes! @airports.delete(airport.site_number)
        end
        @airports.each do |_, attrs|
          Airport.create! attrs
        end
      end
    end

    def map_attributes(attributes)
      {
        name: attributes[:name].titleize,
        city: attributes[:city].titleize,
      }.reverse_merge(attributes)
    end
  end
end
