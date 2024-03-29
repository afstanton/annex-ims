class Batch < ApplicationRecord
  enum batch_type: { regular: 0, deaccession_unstocked: 1 }

  has_many :matches
  has_many :requests, -> { distinct }, through: :matches
  has_many :items, through: :matches
  belongs_to :user

  validates :user_id, presence: true

  def skipped_matches
    matches.where(processed: 'skipped')
  end

  def unprocessed_matches_for_request(request)
    matches.where(processed: nil, request: request.id)
  end

  def unprocessed_matches
    matches.where('processed is null')
  end

  def current_match
    matches.
      where(processed: nil).
      includes(item: { tray: :shelf }).
      order('shelves.barcode').
      order('trays.barcode').
      order('items.title').
      order('items.chron').
      take
  end
end
