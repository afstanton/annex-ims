require 'rails_helper'

RSpec.describe ShelvesController, type: :controller do
  let(:user) { FactoryGirl.create(:user, admin: true) }
  let(:shelf) { FactoryGirl.create(:shelf) }
  let(:tray) { FactoryGirl.create(:tray, shelf: shelf) }
  let(:bogus) { 'BOGUS' }
  let(:barcode) { "00000007819006" }
  let(:metadata_status) { "not_found" }    
  let(:item) { instance_double(Item, barcode: bogus, metadata_status: metadata_status, metadata_updated_at: 1.day.ago, attributes: {}, update!: true) }
  let(:item2) { FactoryGirl.create(:item, tray: tray) }

  before(:each) do
    sign_in(user)

    allow_any_instance_of(GetItemFromBarcode).to receive(:item).and_return(item)
    @bogus_item_uri = api_item_metadata_url(bogus)
    stub_request(:get, @bogus_item_uri).
      with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Faraday v0.9.1'}).
      to_return(:status => 404, :body => "Not Found", :headers => {})
  end

  describe 'POST scan' do
    it 'redirects' do
      post :scan, shelf: { barcode: 'SHELF-AL123' }
      expect(response).to be_redirect
      expect(response.location).to match(/shelves\/items\/\d+/)
    end

    it 'calls notify_airbrake on error and redirects to the trays path' do
      expect(controller).to receive(:notify_airbrake).with(kind_of(RuntimeError))
      post :scan, shelf: { barcode: '12345' }
      expect(response).to redirect_to(shelves_path)
    end
  end

  describe 'POST associate' do
    it 'redirects if an item is not found' do
      post :associate, id: shelf.id, barcode: 'BOGUS'
      expect(response).to be_redirect
      expect(response.location).to match(/shelves\/items\/\d+/)
    end

    it 'handles failure of AssociateShelfWithItemBarcode' do
      item2.tray = nil
      item2.shelf = nil
      item2.save!
      allow(GetItemFromBarcode).to receive(:call).and_return(item2)
      allow(AssociateShelfWithItemBarcode).to receive(:call).and_raise(StandardError)
      expect(controller).to receive(:notify_airbrake).with(kind_of(StandardError))
      post :associate, id: shelf.id, barcode: item2.barcode
      expect(response).to be_redirect
      expect(response.location).to match(/shelves\/items\/\d+/)
    end
  end

  describe 'GET missing' do
    it 'renders the missing template' do
      get :missing, id: shelf.id
      expect(response).to render_template(:missing)
    end
  end

  describe 'POST dissociate' do
    subject { post :dissociate, id: shelf.id, item_id: item2.id, commit: commit }
    context 'Unstocking an item' do
      let(:commit) { 'Unstock' }

      it 'succeeds' do
        subject
        expect(response).to be_redirect
        expect(response.location).to match(/shelves\/items\/\d+/)
      end

      it 'fails' do
        allow(UnstockItem).to receive(:call).and_return(false)
        expect{subject}.to raise_error(RuntimeError, 'unable to unstock item')
      end
    end

    context 'Not unstocking an item' do
      let(:commit) { 'Not' }

      it 'succeeds' do
        subject
        expect(response).to be_redirect
        expect(response.location).to match(/shelves\/items\/\d+/)
      end

      it 'fails' do
        allow(DissociateShelfFromItem).to receive(:call).and_return(false)
        expect{subject}.to raise_error(RuntimeError, 'unable to dissociate')
      end
    end
  end
end
