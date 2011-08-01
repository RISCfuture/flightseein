require 'spec_helper'
require 'parser/logten_parser'

describe Importer do
  context "[decompression]" do
    it "should skip unknown files" do
      LogtenParser.should_not_receive(:new)
      import = FactoryGirl.create(:import, logbook: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'bogus.zip'), 'application/zip'))
      Importer.new(import).perform
    end

    context "[known files]" do
      before :each do
        parser = mock('LogtenParser')
        LogtenParser.should_receive(:new).once.with(an_instance_of(Import), /\/Logbook\.logten$/).and_return(parser)
        parser.should_receive(:process).once
      end

      it "should decompress a .zip file" do
        import = FactoryGirl.create(:import, logbook: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'logten.zip'), 'application/zip'))
        Importer.new(import).perform
      end

      it "should decompress a .tar.gz file" do
        import = FactoryGirl.create(:import, logbook: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'logten.tar.gz'), 'application/x-gzip'))
        Importer.new(import).perform
      end

      it "should decompress a .tar.bz2 file" do
        import = Factory(:import, logbook: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'logten.tar.bz2'), 'application/x-bzip2'))
        Importer.new(import).perform
      end
    end
  end
end
