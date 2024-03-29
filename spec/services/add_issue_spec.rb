require 'rails_helper'

RSpec.describe AddIssue do
  let(:item) { create(:item) }
  let(:user) { create(:user) }
  let(:issue_type) { 'not_found' }
  let(:message) { 'item was not found' }
  subject { described_class.call(item: item, user: user, type: issue_type, message: message) }

  it 'creates an issue with the correct type, barcode, message and user' do
    expect { subject }.to change { Issue.count }.from(0).to(1)
    expect(subject.user).to eq(user)
    expect(subject.issue_type).to eq(issue_type)
    expect(subject.barcode).to eq(item.barcode)
    expect(subject.message).to eq(message)
  end

  it 'logs the issue creation' do
    expect(ActivityLogger).to receive(:create_issue).with(item: item, issue: kind_of(Issue), user: user)
    subject
  end

  it 'does not create a second issue for the same type' do
    issue = described_class.call(item: item, user: user, type: issue_type, message: message)
    expect(subject).to eq(issue)
  end

  it 'creates a second issue for a different type' do
    issue = described_class.call(item: item, user: user, type: 'not_for_annex')
    expect(subject).to_not eq(issue)
  end

  it 'creates a third issue for a different type' do
    issue = described_class.call(item: item, user: user, type: 'not_valid_barcode')
    expect(subject).to_not eq(issue)
  end

  it 'creates a second for a different item' do
    other_item = create(:item)
    issue = described_class.call(item: other_item, user: user, type: issue_type)
    expect(subject).to_not eq(issue)
  end
end
