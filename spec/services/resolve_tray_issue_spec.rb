require 'rails_helper'

RSpec.describe ResolveTrayIssue do
  let(:issue) { create(:tray_issue) }
  let(:tray) { create(:tray) }
  let(:user) { create(:user) }
  subject { described_class.call(tray: tray, issue: issue, user: user) }

  it 'resolves the tray issue' do
    expect(issue.resolved_at).to be_nil
    expect(issue.resolver).to be_nil
    subject
    expect(issue.resolved_at).to be >= Time.now - 1.second
    expect(issue.resolver).to eq(user)
  end

  it 'logs the tray issue resolution' do
    expect(ActivityLogger).to receive(:resolve_tray_issue).with(tray: tray, issue: issue, user: user)
    subject
  end
end
