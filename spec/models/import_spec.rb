require 'spec_helper'

describe Import do
  describe "#enqueue" do
    it "should use Resque to enqueue an import operation" do
      import = Factory(:import)
      Resque.should_receive(:enqueue).once.with(Import, import.id)
      import.enqueue
    end
  end

  describe ".perform" do
    it "should locate a record by ID and import it" do
      import = Factory(:import)
      importer = mock('Importer')
      importer.should_receive(:perform).once
      Importer.should_receive(:new).once.with(import).and_return(importer)
      Import.perform(import.id)
    end
  end

  describe "#perform!" do
    it "should create an Importer and call #perform" do
      import = Factory(:import)
      importer = mock('Importer')
      importer.should_receive(:perform).once
      Importer.should_receive(:new).once.with(import).and_return(importer)
      import.perform!
    end
  end
end
