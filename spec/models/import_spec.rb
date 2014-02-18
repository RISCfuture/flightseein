require 'spec_helper'

describe Import do
  describe "#enqueue" do
    it "should use Sidekiq to enqueue an import operation" do
      Importer.drain
      import = FactoryGirl.create(:import)
      import.enqueue
      expect(Importer.jobs.size).to eql(1)
    end
  end
end
