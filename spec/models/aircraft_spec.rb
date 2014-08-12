require 'rails_helper'

describe Aircraft, type: :model do
  describe "#ident" do
    it "should be upcased" do
      expect(FactoryGirl.create(:aircraft, ident: 'n21051').ident).to eql('N21051')
    end
  end
end
