require "rails_helper"

RSpec.describe DeaccessionItem do
  let(:item) { create(:item, tray: tray, thickness: 1, disposition: disposition) }
  let(:tray) { create(:tray) }
  let(:shelf) { create(:shelf) }
  let(:user) { create(:user) }
  let(:disposition) { create(:disposition) }
  subject { described_class.call(item, user) }

  it "sets deaccessioned" do
    expect(item).to receive("deaccessioned!")
    subject
  end

  it "logs the activity" do
    expect(ActivityLogger).to receive(:deaccession_item).with(item: item, user: user, disposition: item.disposition, comment: { comment: nil })
    subject
  end

  it "returns the item when it is successful" do
    allow(item).to receive(:save).and_return(true)
    expect(subject).to be(item)
  end

  it "returns false when it is unsuccessful" do
    allow(item).to receive("save!").and_return(false)
    expect(subject).to be(false)
  end

  it "queues a background job" do
    expect(ApiDeaccessionItemJob).to receive(:perform_later).with(item: item)
    subject
  end
end
