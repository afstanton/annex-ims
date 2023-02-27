require "rails_helper"

RSpec.describe UnresolvedIssueQuery do
  subject { described_class }

  it "will query for all issues that have not been resolved" do
    relation = double
    expect(relation).to receive(:where).with(resolved_at: nil)
    subject.call({}, relation: relation)
  end

  it "will allow filtering by barcode" do
    issue1 = create(:issue)
    issue2 = create(:issue)

    # This one won't show up in the response object
    create(:issue, resolved_at: Time.now)

    # Overloading expectations so we don't need
    expect(subject.call(barcode: issue1.barcode)).to eq([issue1])
    expect(subject.call(barcode: "")).to eq([issue1, issue2])
    expect(subject.call({})).to eq([issue1, issue2])
  end
end
