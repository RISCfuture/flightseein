require 'rails_helper'

RSpec.describe ImporterJob, type: :job do
  context "[decompression]" do
    it "should skip unknown files" do
      expect(LogtenSixParser).not_to receive(:new)
      expect(LogtenParser).not_to receive(:new)
      import = FactoryGirl.create(:import, logbook: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'bogus.zip'), 'application/zip'))
      ImporterJob.new.perform import
    end

    context "[known files]" do
      before :each do
        parser = double('LogtenSixParser')
        expect(LogtenSixParser).to receive(:new).once.with(an_instance_of(Import), /\/LogTenProData$/).and_return(parser)
        expect(parser).to receive(:process).once
      end

      it "should decompress a .zip file" do
        import = FactoryGirl.create(:import, logbook: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'logten.zip'), 'application/zip'))
        ImporterJob.new.perform import
      end

      it "should decompress a .tar.gz file" do
        import = FactoryGirl.create(:import, logbook: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'logten.tar.gz'), 'application/x-gzip'))
        ImporterJob.new.perform import
      end

      it "should decompress a .tar.bz2 file" do
        import = FactoryGirl.create(:import, logbook: Rack::Test::UploadedFile.new(Rails.root.join('spec', 'fixtures', 'logten.tar.bz2'), 'application/x-bzip2'))
        ImporterJob.new.perform import
      end
    end
  end
end
