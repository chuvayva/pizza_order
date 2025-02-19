require 'rails_helper'

RSpec.describe "Orders", type: :request do
  describe "GET /orders" do
    subject(:get_orders) { get orders_path }

    before(:each) do
      create :order, :simple
      create :order, :with_addons
      create :order, :with_promotion
    end

    it "returns http success" do
      get_orders
      expect(response).to have_http_status(:ok)
    end

    it 'renders 3 orders' do
      get_orders

      document = Nokogiri::HTML(response.body)
      order_elements = document.css('[id^="order_"]')

      expect(order_elements.count).to eq(3)
    end
  end
end
