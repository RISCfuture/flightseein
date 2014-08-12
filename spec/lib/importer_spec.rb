require 'rails_helper'
require 'parser/logten_parser'
require 'importer'

describe Importer do
  context "[decompression]" do
    it "should skip unknown files" do
      expect(LogtenSixParser).not_to receive(:new)
      import = FactoryGirl.create(:import, logbook: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'bogus.zip'), 'application/zip'))
      Importer.new.perform import.id
    end

    context "[known files]" do
      before :each do
        parser = double('LogtenParser')
        expect(LogtenParser).to receive(:new).once.with(an_instance_of(Import), /\/Logbook.logten$/).and_return(parser)
        expect(parser).to receive(:process).once
      end

      it "should decompress a .zip file" do
        import = FactoryGirl.create(:import, logbook: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'logten.zip'), 'application/zip'))
        Importer.new.perform import.id
      end

      it "should decompress a .tar.gz file" do
        import = FactoryGirl.create(:import, logbook: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'logten.tar.gz'), 'application/x-gzip'))
        Importer.new.perform import.id
      end

      it "should decompress a .tar.bz2 file" do
        import = FactoryGirl.create(:import, logbook: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'logten.tar.bz2'), 'application/x-bzip2'))
        Importer.new.perform import.id
      end
    end
  end
end
