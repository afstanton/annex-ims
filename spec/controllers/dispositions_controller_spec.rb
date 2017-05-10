require "rails_helper"

RSpec.describe DispositionsController, type: :controller do
  let(:user) { FactoryGirl.create(:user, admin: true) }
  let(:disposition) { FactoryGirl.create(:disposition, active: true) }
  let(:item) { FactoryGirl.create(:item) }

  before(:each) do
    sign_in(user)
  end

  describe "GET index" do
    subject { get :index }
    it "renders index view" do
      subject
      expect(response).to render_template(:index)
    end
  end

  describe "POST activation" do
    subject { post :activation, id: disposition.id }
    it "updates a disposition" do
      disposition
      expect(Disposition.first.active).to eq true
      subject
      expect(Disposition.first.active).to eq false
    end
  end

  describe "POST create" do
    subject { post :create, disposition: { code: "WDR-Damaged" } }
    it "creates a disposition" do
      expect(Disposition).to receive(:new).with(code: "WDR-Damaged").and_return(disposition)
      subject
    end
  end

  describe "GET show" do
    subject { get :show, id: disposition.id }
    it "renders show view" do
      subject
      expect(response).to render_template(:show)
    end
  end

  describe "PUT update" do
    subject { put :update, id: disposition.id,  disposition: { active: false } }
    it "updates a disposition" do
      disposition
      expect(Disposition.first.active).to eq true
      subject
      expect(Disposition.first.active).to eq false
    end
  end

  describe "DELETE destroy" do
    subject { delete :destroy, id: disposition.id }
    it "deletes one disposition" do
      disposition
      expect(Disposition.all.count).to eq 1
      subject
      expect(Disposition.all.count).to eq 0
    end
  end
end
