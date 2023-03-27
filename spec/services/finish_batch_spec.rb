require 'rails_helper'

RSpec.describe FinishBatch do
  let(:shelf) { create(:shelf) }
  let(:tray) { create(:tray, shelf: shelf) }
  let(:batch) { create(:batch, user: user) }
  let(:user) { create(:user) }

  let(:item1) { create(:item, tray: tray, thickness: 1) }
  let(:item2) { create(:item, tray: tray, thickness: 1) }
  let(:item3) { create(:item, tray: tray, thickness: 1) }

  let(:match1) { create(:match, batch: batch, item: item1) }
  let(:match2) { create(:match, batch: batch, item: item2) }
  let(:match3) { create(:match, batch: batch, item: item3) }

  let(:subject) { FinishBatch.call(match1.batch, user) }

  context 'when there are no remaining matches for the batch' do
    let(:current_instance) { FinishBatch.new(match1.batch, user) }
    before(:each) do
      match1
      match2
      match3
    end

    describe '#finish!' do
      it 'returns true' do
        match1.destroy!
        match2.destroy!
        match3.destroy!
        expect(current_instance.finish!).to be_truthy
      end
    end

    describe '#remaining_matches' do
      it 'returns false' do
        match1.destroy!
        match2.destroy!
        match3.destroy!
        expect(current_instance.remaining_matches?).to be_falsey
      end
    end
  end

  context 'when there are remaining matches for the batch' do
    let(:current_instance) { FinishBatch.new(match1.batch, user) }
    before(:each) do
      match1
      match2
      match3
    end

    describe '#finish!' do
      it 'returns false' do
        expect(current_instance.finish!).to be_falsey
      end
    end

    describe '#remaining_matches' do
      it 'returns true' do
        expect(current_instance.remaining_matches?).to be_truthy
      end
    end
  end
end
