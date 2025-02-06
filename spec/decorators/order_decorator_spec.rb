require 'rails_helper'

RSpec.describe OrderDecorator do
  let(:order) { create :order, :with_promotion, created_at: Time.zone.local(2025, 2, 5, 14, 0, 0) }
  let(:decorated_order) { described_class.decorate(order) }

  describe '#total_price' do
    subject { decorated_order.total_price }
    it { should eql "€16.29" }
  end

  describe '#created_at' do
    subject { decorated_order.created_at }
    it { should eql "February 05, 2025 14:00" }
  end

  describe '#promotion_codes' do
    subject { decorated_order.promotion_codes }
    it { should eql "2FOR1" }

    context "when no promotion codes" do
      let(:order) { create :order, :simple }
      it { should eql "-" }
    end
  end

  describe '#discount_code' do
    subject { decorated_order.discount_code }
    it { should eql "SAVE5" }

    context "when no discount codes" do
      let(:order) { create :order, :simple }
      it { should eql "-" }
    end
  end
end
