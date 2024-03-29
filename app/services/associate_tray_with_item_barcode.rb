class AssociateTrayWithItemBarcode
  attr_reader :user_id, :tray, :barcode, :thickness

  def self.call(user_id, tray, barcode, thickness)
    new(user_id, tray, barcode, thickness).associate!
  end

  def initialize(user_id, tray, barcode, thickness)
    @user_id = user_id
    @tray = tray
    @barcode = barcode
    @thickness = thickness
  end

  def associate!
    validate_input!

    item = GetItemFromBarcode.call(barcode: barcode, user_id: user_id)
    if !item.nil?
      item.tray = tray
      item.thickness = thickness
      if item.save!
        user = User.find(user_id)
        ActivityLogger.associate_item_and_tray(item: item, tray: item.tray, user: user)
        StockItem.call(item, user)
        item
      else
        false
      end
    else
      raise "item #{barcode} not found"
    end
  end

    private

  def validate_input!
    if IsObjectTray.call(tray)
      true
    else
      raise 'object is not a tray'
    end
  end
  end
