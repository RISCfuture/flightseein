require 'rails_helper'

describe Import, type: :model do
  describe "#enqueue" do
    it "should use ActiveJob to enqueue an import operation" do
      import = FactoryBot.create(:import)
      import.enqueue
      expect(ImporterJob).to have_been_enqueued.with({'_aj_globalid' =>import.to_global_id.to_s})
    end
  end
end
