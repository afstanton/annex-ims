require 'rails_helper'

feature "Build", :type => :feature, :search => true do
  include AuthenticationHelper

  describe "when signed in", js: true do

    let(:shelf) { FactoryGirl.build(:shelf) }
    let(:tray) { FactoryGirl.build(:tray, barcode: 'TRAY-AH12345', shelf: shelf) }
    let(:tray2) { FactoryGirl.build(:tray, barcode: 'TRAY-BL6789', shelf: shelf) }

    let(:item) { FactoryGirl.build(:item,
                                    author: 'JOHN DOE',
                                    title: 'SOME TITLE',
                                    chron: 'TEST CHRN',
                                    bib_number: '12345',
                                    barcode: '9876543',
                                    isbn_issn: '987655432',
                                    call_number: 'A 123 .C654 1991',
                                    thickness: 1,
                                    tray: tray,
                                    initial_ingest: 3.days.ago.strftime("%Y-%m-%d"),
                                    last_ingest: 3.days.ago.strftime("%Y-%m-%d"),
                                    conditions: ["COVER-TORN","COVER-DET"]) }

    let(:item2) { FactoryGirl.build(:item,
                                    author: 'BUBBA SMITH',
                                    title: 'SOME OTHER TITLE',
                                    chron: 'TEST CHRN 2',
                                    bib_number: '12345',
                                    barcode: '4576839201',
                                    isbn_issn: '918273645',
                                    call_number: 'A 1234 .C654 1991',
                                    thickness: 1,
                                    tray: tray2,
                                    initial_ingest: 1.day.ago.strftime("%Y-%m-%d"),
                                    last_ingest: 1.day.ago.strftime("%Y-%m-%d"),
                                    conditions: ["COVER-TORN","PAGES-DET"])}

    let(:request1) { FactoryGirl.build(:request,
                                        criteria_type: 'barcode',
                                        criteria: item.barcode,
                                        barcode: item.barcode,
                                        requested: 3.days.ago.strftime("%Y-%m-%d")) }

    let(:request2) { FactoryGirl.build(:request,
                                        criteria_type: 'barcode',
                                        criteria: item2.barcode,
                                        barcode: item2.barcode,
                                        requested: 1.day.ago.strftime("%Y-%m-%d")) }

    before(:each) do
      login_admin
    end

    it "doesn't build a batch when no items are selected", :search => true do
      allow_any_instance_of(GetRequests).to receive(:get_data!).and_return(nil)
      visit batches_path
      click_button "Save"
      expect(current_path).to eq(batches_path)
      expect(page).to have_content "No items selected."
    end

    # This needs to be in an integration test suite
    # it "builds a batch when an item is selected", :search => true do
    #   allow_any_instance_of(GetRequests).to receive(:get_data!).and_return(nil)
    #   visit batches_path
    #   find(:css, "[id='request_#{request1.id}']").click
    #   find(:id, "#{request1.id}-#{item.id}").set(true)
    #   click_button "Save"
    #   expect(current_path).to eq(root_path)
    #   expect(page).to have_content "Batch created."
    # end

    # it "can see an item on the batch list once selected", :search => true do
    #   allow_any_instance_of(GetRequests).to receive(:get_data!).and_return(nil)
    #   visit batches_path
    #   find(:css, "[id='request_#{request1.id}']").click
    #   find(:id, "#{request1.id}-#{item.id}").set(true)
    #   click_button "Save"
    #   expect(current_path).to eq(root_path)
    #   expect(page).to have_content "Batch created."
    #   visit current_batch_path
    #   expect(page).to have_content item.title
    #   expect(page).to have_content item.author
    # end

  end
end
