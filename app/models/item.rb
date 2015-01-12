class Item < ActiveRecord::Base
  validates_presence_of :barcode
  validates_presence_of :thickness, on: :update  # Items are going to be programmatically created, humans will be required to enter thickness.
  validates :barcode, uniqueness: true
  validate :has_correct_prefix

  belongs_to :tray
  has_one :shelf, through: :tray

  def has_correct_prefix
    if !IsItemBarcode.call(barcode)
      errors.add(:barcode, "must not begin with #{IsShelfBarcode::PREFIX}, #{IsTrayBarcode::PREFIX}, or #{IsToteBarcode::PREFIX}")
    end
  end
end
