require 'spec_helper'

describe Import do
  describe "#enqueue" do
    it "should use Sidekiq to enqueue an import operation" do
      Importer.drain
      import = FactoryGirl.create(:import)
      import.enqueue
      Importer.jobs.size.should eql(1)
    end
  end
end
