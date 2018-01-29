require 'rails_helper'

feature "Update", type: :feature do
  include AuthenticationHelper

  describe "as an admin" do
    before(:each) do
      login_admin
      visit root_path
    end

    it "can see Update Barcode in the menu" do
      click_link "Items"
      expect(page).to have_content "Update Barcode"
    end

    it "can access the Update Barcode page" do
      click_link "Items"
      click_link "Update Barcode"
      expect(current_path).to eq(update_path)
    end
  end

  describe "as a worker" do
    before(:each) do
      login_worker
      visit root_path
    end

    it "cannot see Update Barcode in the menu" do
      click_link "Items"
      expect(page).to_not have_content "Update Barcode"
    end
  end
end
