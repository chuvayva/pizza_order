require 'rails_helper'

RSpec.describe "Orders", type: :request do
  describe "PATCH /order/:id" do
    subject(:update_order) { patch order_path(order), params:, headers: }

    let(:params) { { order: { state: :completed } } }
    let(:headers) { { 'Accept' => Mime[:turbo_stream].to_s } }
    let!(:order) { create :order, :simple, state: :open }

    it "returns http success" do
      update_order
      expect(response).to have_http_status(:ok)
    end

    it 'returns turbo stream' do
      update_order

      document = Nokogiri::HTML(response.body)
      turbo_stream = document.css('turbo-stream[action="remove"]')

      expect(turbo_stream).to be
    end

    it 'updates order state' do
      update_order
      expect(order.reload.state).to eql "completed"
    end
  end
end
