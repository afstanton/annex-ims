class ItemRestockToTray
  attr_reader :item_id, :barcode, :user

  def self.call(item_id, barcode, user)
    new(item_id, barcode, user).process!
  end

  def initialize(item_id, barcode, user)
    @item_id = item_id
    @barcode = barcode
    @user = user
  end

  def process!
    results = {}
    results[:error] = nil
    results[:notice] = nil
    results[:path] = nil

    item = Item.find(@item_id)
    tray = GetTrayFromBarcode.call(barcode)

    if item.tray.blank? # couldn't figure out how to make link_to work here with doing an include
      results[:error] = 'This item has no tray to stock to.'
      results[:path] = h.show_item_path(id: @item_id)
    else
      if item.tray != tray # this isn't the place to be putting items in the wrong tray
        results[:error] = "Item #{item.barcode} is already assigned to #{item.tray.barcode}."
        results[:path] = h.wrong_restock_path(id: @item_id)
      else
        StockItem.call(item, @user)
        results[:notice] = "Item #{item.barcode} stocked in #{tray.barcode}."
        results[:path] = h.items_path
      end
    end

    results
  end

  def h
    Rails.application.routes.url_helpers
  end
end
