require 'spec_helper'
require 'parser/logten_parser'

describe Importer do
  context "[decompression]" do
    it "should skip unknown files" do
      LogtenParser.should_not_receive(:new)
      import = Factory(:import, logbook: open(Rails.root.join('spec', 'fixtures', 'bogus.zip')))
      Importer.new(import).perform
    end

    context "[known files]" do
      before :each do
        parser = mock('LogtenParser')
        LogtenParser.should_receive(:new).once.with(an_instance_of(Import), /\/Logbook\.logten$/).and_return(parser)
        parser.should_receive(:process).once
      end

      it "should decompress a .zip file" do
        import = Factory(:import, logbook: open(Rails.root.join('spec', 'fixtures', 'logten.zip')))
        Importer.new(import).perform
      end

      it "should decompress a .tar.gz file" do
        import = Factory(:import, logbook: open(Rails.root.join('spec', 'fixtures', 'logten.tar.gz')))
        Importer.new(import).perform
      end

      it "should decompress a .tar.bz2 file" do
        import = Factory(:import, logbook: open(Rails.root.join('spec', 'fixtures', 'logten.tar.bz2')))
        Importer.new(import).perform
      end
    end
  end
end
