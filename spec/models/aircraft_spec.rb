require 'spec_helper'

describe Aircraft do
  describe "#ident" do
    it "should be upcased" do
      Factory(:aircraft, ident: 'n21051').ident.should eql('N21051')
    end
  end
end
