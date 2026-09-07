require 'rails_helper'

RSpec.describe Pricing::NForMPromotion do
  describe '.run' do
    subject { described_class.run(order, options).to_f }

    let(:order) { instance_double(Order, order_items: items) }
    let(:items) { Array.new(count) { instance_double(OrderItem, name: "Salami", size: "Small") } }

    context "with a 2-for-1 promotion" do
      let(:options) { { "target" => "Salami", "target_size" => "Small", "from" => 2, "to" => 1 } }

      context "when there is a single target pizza" do
        let(:count) { 1 }
        it { should eql 0.0 }
      end

      context "when there is one complete group" do
        let(:count) { 2 }
        it { should eql 4.2 }
      end

      context "when there is one complete group and a leftover pizza" do
        let(:count) { 3 }
        it { should eql 4.2 }
      end

      context "when there are two complete groups" do
        let(:count) { 4 }
        it { should eql 8.4 }
      end

      context "when there are two complete groups and a leftover pizza" do
        let(:count) { 5 }
        it { should eql 8.4 }
      end
    end

    context "with a 3-for-2 promotion" do
      let(:options) { { "target" => "Salami", "target_size" => "Small", "from" => 3, "to" => 2 } }

      context "when there is one complete group" do
        let(:count) { 3 }
        it { should eql 4.2 }
      end

      context "when there are two complete groups" do
        let(:count) { 6 }
        it { should eql 8.4 }
      end
    end

    context "when the items do not match the promotion target" do
      let(:options) { { "target" => "Salami", "target_size" => "Small", "from" => 2, "to" => 1 } }
      let(:items) { [ instance_double(OrderItem, name: "Salami", size: "Medium") ] * 4 }

      it { should eql 0.0 }
    end
  end
end
