require 'rails_helper'

RSpec.describe Pricing::Calculator do
  describe '.total_price' do
    subject { described_class.total_price(order).to_f }

    context "when order is simple" do
      let(:order) { create :order, :simple }
      it { should eql 10.4 }
    end

    context "when order has addons" do
      let(:order) { create :order, :with_addons }
      it { should eql 13.65 }
    end

    context "when order has omitted ingredients" do
      let(:order) { create :order, :with_removals }
      it { should eql 6.5 }
    end

    context "when order has discount" do
      let(:order) { create :order, :with_discount }
      it { should eql 9.69 }
    end

    context "when order has promotion" do
      let(:order) { create :order, :with_promotion }
      it { should eql 16.29 }
    end
  end
end
