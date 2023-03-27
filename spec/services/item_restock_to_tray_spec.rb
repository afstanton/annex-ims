require 'rails_helper'

def h
  Rails.application.routes.url_helpers
end

RSpec.describe ItemRestockToTray do
  before(:each) do
    @tray = create(:tray)
    @shelf = create(:shelf)
    @tray2 = create(:tray)
    @item = create(:item, tray: @tray)
    @item2 = create(:item)
    @user = create(:user)

    stub_request(:post, api_stock_url).
      with(body: { 'barcode' => @item.barcode.to_s, 'item_id' => @item.id.to_s, 'tray_code' => @item.tray.barcode.to_s },
           headers: { 'Content-Type' => 'application/x-www-form-urlencoded', 'User-Agent' => 'Faraday v1.10.3' }).
      to_return { |_response| { status: 200, body: { results: { status: 'OK', message: 'Item stocked' } }.to_json, headers: {} } }

    @user_id = 1 # Just fake having a user here
  end

  it 'runs a test and expect errors' do
    barcode = 'TRAY-AL1234'
    results = ItemRestockToTray.call(@item2.id, barcode, @user)
    expect(results[:error]).to eq('This item has no tray to stock to.')
    expect(results[:notice]).to eq(nil)
    expect(results[:path]).to eq(h.show_item_path(id: @item2.id))
  end

  it 'stocks an item to a tray' do
    results = ItemRestockToTray.call(@item.id, @tray.barcode, @user)
    expect(results[:error]).to eq(nil)
    expect(results[:notice]).to eq("Item #{@item.barcode} stocked in #{@tray.barcode}.")
    expect(results[:path]).to eq(h.items_path)
  end

  it 'rejects a wrong tray scan' do
    results = ItemRestockToTray.call(@item.id, @tray2.barcode, @user)
    expect(results[:error]).to eq("Item #{@item.barcode} is already assigned to #{@tray.barcode}.")
    expect(results[:notice]).to eq(nil)
    expect(results[:path]).to eq(h.wrong_restock_path(id: @item.id))
  end
end
