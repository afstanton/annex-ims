# frozen_string_literal: true

class Item < ApplicationRecord
  searchkick index_prefix: "ims"

  CONDITIONS = %w[
    COVER-DET
    COVER-MISS
    COVER-TORN
    NEEDS-ENCLS
    PAGES-BRITTLE
    PAGES-DET
    PAGES-MISSING
    PAGES-TORN
    REDROT
    SPINE-DET
    UNBOUND
    OTHER
  ].freeze

  METADATA_STATUSES = %w[
    pending
    complete
    not_found
    not_for_annex
    error
  ].freeze

  STATUSES = {
    '0' => 'Stocked',
    '1' => 'Unstocked',
    '2' => 'Shipped',
    '3' => 'Deaccessioned'
  }.freeze

  enum status: { stocked: 0, unstocked: 1, shipped: 2, deaccessioned: 9 }

  validates :thickness, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, presence: true, on: :update
  validates :barcode, uniqueness: true, presence: true
  validates :metadata_status, inclusion: METADATA_STATUSES
  validate :has_correct_prefix?
  validates_with BarcodeSpaceValidator

  belongs_to :tray
  belongs_to :bin
  belongs_to :disposition
  has_one :shelf, through: :tray
  has_many :matches
  has_many :requests, through: :matches
  has_many :batches, through: :matches
  has_many :filled_requests,
           class_name: 'Request',
           foreign_key: 'item_id',
           dependent: :restrict_with_exception
=begin
  searchable do
    text :barcode
    text :bib_number
    text :call_number
    text :isbn_issn
    text :title
    text :author
    string :chron
    string :conditions, multiple: true
    date :initial_ingest
    date :last_ingest
    string :tray_barcode do
      tray.present? ? tray.barcode : nil
    end
    string :shelf_barcode do
      shelf.present? ? shelf.barcode : nil
    end
    string :bin_barcode do
      bin.present? ? bin.barcode : nil
    end
    date :requested, multiple: true do
      requests.map &:requested
    end
    string :status
  end
=end

  def search_data
    {
      barcode: barcode,
      bib_number: bib_number,
      call_number: call_number,
      isbn_issn: isbn_issn,
      title: title,
      author: author,
      chron: chron,
      conditions: conditions,
      initial_ingest: initial_ingest,
      last_ingest: last_ingest,
      tray_barcode: tray.present? ? tray.barcode : nil,
      shelf_barcode: shelf.present? ? shelf.barcode : nil,
      bin_barcode: bin.present? ? bin.barcode : nil,
      requested: requests.map(&:requested),
      status: status
    }
  end

  def has_correct_prefix?
    unless IsItemBarcode.call(barcode)
      errors.add(:barcode, "must not begin with #{IsShelfBarcode::PREFIX}, #{IsTrayBarcode.prefix}, or #{IsBinBarcode::PREFIX}")
    end
  end
end
