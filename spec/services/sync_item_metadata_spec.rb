require 'rails_helper'

RSpec.describe SyncItemMetadata do
  let(:barcode) { '00000007819006' }
  let(:item) { create(:item, barcode: barcode, metadata_status: 'pending') }
  let(:user) { create(:user) }
  let(:user_id) { user.id }
  let(:response) { ApiResponse.new(status_code: 200, body: { sublibrary: 'ANNEX' }) }
  let(:background) { false }

  context 'self' do
    subject { described_class }

    describe '#call' do
      subject { described_class.call(item: item, user_id: user_id, background: background) }

      shared_examples 'a metadata status update' do |expected_status|
        it "sets the item metadata_status to #{expected_status}" do
          subject
          expect(item.metadata_status).to eq(expected_status)
        end

        it 'updates the metadata_updated_at' do
          expect(item.metadata_updated_at).to be_nil
          subject
          expect(item.metadata_updated_at).to be_present
          expect(Time.now - item.metadata_updated_at).to be < 1
        end
      end

      shared_examples 'an issue logger' do |expected_issue_type|
        it "calls AddIssue with #{expected_issue_type}" do
          expect(AddIssue).to receive(:call).with(item: item, user: user, type: expected_issue_type)
          subject
        end
      end

      context 'previously synced item' do
        let(:item) { instance_double(Item, metadata_status: 'complete', metadata_updated_at: 23.hours.ago) }

        it 'does not perform a sync' do
          expect(ApiGetItemMetadata).to_not receive(:call)
          expect(subject).to eq(true)
        end
      end

      context 'item synced more than 24 hours ago' do
        let(:item) { instance_double(Item, metadata_status: 'complete', metadata_updated_at: 28.hours.ago, update!: true, attributes: {}) }

        it 'does not perform a sync' do
          expect(ApiGetItemMetadata).to receive(:call).and_return(response)
          expect(subject).to eq(true)
        end
      end

      context 'recently updated item in error' do
        let(:item) { instance_double(Item, barcode: barcode, metadata_status: 'error', metadata_updated_at: 1.minute.ago, update!: true, attributes: {}) }

        context 'foreground sync' do
          let(:background) { false }

          it 'does not perform a sync' do
            expect(ApiGetItemMetadata).to_not receive(:call)
            expect(subject).to eq(true)
          end
        end

        context 'background sync' do
          let(:background) { true }

          it 'performs a sync' do
            expect(ApiGetItemMetadata).to receive(:call).and_return(response)
            expect(subject).to eq(true)
          end
        end
      end

      context 'pending item' do
        let(:item) { instance_double(Item, barcode: barcode, metadata_status: 'pending', update!: true, metadata_updated_at: 1.day.ago, attributes: {}) }

        it 'performs a sync' do
          expect(ApiGetItemMetadata).to receive(:call).and_return(response)
          expect(subject).to eq(true)
        end
      end

      context 'error item' do
        let(:item) { instance_double(Item, barcode: barcode, metadata_status: 'error', update!: true, metadata_updated_at: 1.day.ago, attributes: {}) }

        it 'performs a sync' do
          expect(ApiGetItemMetadata).to receive(:call).and_return(response)
          expect(subject).to eq(true)
        end
      end

      context 'no user id' do
        subject { described_class.new(item: item, user_id: nil, background: background) }
        it 'returns nil' do
          expect(subject.send(:user)).to be_nil
        end
      end

      context 'not_found item' do
        let(:item) { instance_double(Item, barcode: barcode, metadata_status: 'not_found', update!: true, metadata_updated_at: 1.day.ago, attributes: {}) }

        it 'performs a sync' do
          expect(ApiGetItemMetadata).to receive(:call).and_return(response)
          expect(subject).to eq(true)
        end
      end

      context 'success' do
        before do
          stub_api_item_metadata(barcode: barcode)
        end

        it 'updates the item metadata' do
          expect(subject).to eq(true)
          expect(item.title).to eq('The ubiquity of chaos / edited by Saul Krasner.')
          expect(item.author).to eq('Author')
          expect(item.chron).to eq('Description')
          expect(item.bib_number).to eq('000841979')
          expect(item.isbn_issn).to eq('0871683504')
          expect(item.conditions).to eq(['Condition'])
          expect(item.call_number).to eq('Q 172.5 .C45 U25 1990')
        end

        it 'logs the activity' do
          expect(ActivityLogger).to receive(:update_item_metadata).with(item: item)
          expect(subject).to eq(true)
        end
      end

      context 'timeout' do
        before do
          stub_request(:get, api_item_metadata_url(barcode)).to_raise(Faraday::TimeoutError)
        end

        it 'returns false and is a timeout response' do
          expect(subject).to eq(false)
          expect(item.metadata_status).to eq('error')
        end
      end

      context 'error response' do
        let(:body_json) { { sublibrary: 'ANNEX' }.to_json }

        before do
          stub_api_item_metadata(barcode: barcode, status_code: status_code, body: body_json)
        end

        shared_examples 'an error response' do
          it 'returns false' do
            expect(subject).to eq(false)
          end
        end

        shared_examples 'a response that queues a background job' do
          it 'queues a background job' do
            expect(SyncItemMetadataJob).to receive(:perform_later).with(item: item, user_id: user_id)
            subject
          end

          context 'in background' do
            let(:background) { true }

            it 'raises an exception' do
              expect { subject }.to raise_error(described_class::SyncItemMetadataError)
            end
          end
        end

        context '500 error' do
          let(:status_code) { 500 }

          it_behaves_like 'an error response'

          it_behaves_like 'a metadata status update', 'error'

          it_behaves_like 'a response that queues a background job'
        end

        context 'not found error' do
          let(:status_code) { 404 }

          it_behaves_like 'an error response'

          it_behaves_like 'a metadata status update', 'not_found'

          it 'does not queue a background job' do
            expect(SyncItemMetadataJob).to_not receive(:perform_later)
            subject
          end

          it_behaves_like 'an issue logger', 'not_found'
        end

        context 'timeout error' do
          let(:status_code) { 599 }

          it_behaves_like 'an error response'

          it_behaves_like 'a metadata status update', 'error'

          it_behaves_like 'a response that queues a background job'
        end

        context 'unauthorized error' do
          let(:status_code) { 401 }

          it_behaves_like 'an error response'

          it_behaves_like 'a metadata status update', 'error'

          it_behaves_like 'a response that queues a background job'
        end

        context 'no sublibrary code' do
          let(:body_json) { {}.to_json }
          let(:status_code) { 200 }

          it_behaves_like 'a metadata status update', 'not_for_annex'

          it_behaves_like 'an issue logger', 'not_for_annex'
        end

        context 'sublibrary code is not ANNEX' do
          let(:body_json) { { sublibrary: 'SOMETHINGELSE' }.to_json }
          let(:status_code) { 200 }

          it_behaves_like 'a metadata status update', 'not_for_annex'

          it_behaves_like 'an issue logger', 'not_for_annex'
        end
      end
    end
  end
end
