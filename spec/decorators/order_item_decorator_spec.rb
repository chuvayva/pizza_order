require 'rails_helper'

RSpec.describe OrderItemDecorator do
  let(:order_item) { create :order_item, name: "Salami", size: "Medium", addons: [ "Onions", "Mushrooms" ],
                            removals: [ "Cheese", "Cucumbers" ] }
  let(:decorated_order_item) { described_class.decorate(order_item) }

  describe '#name' do
    subject { decorated_order_item.name }
    it { should eql "Salami (Medium)" }
  end

  describe '#addons_string' do
    subject { decorated_order_item.addons_string }
    it { should eql "Onions, Mushrooms" }
  end

  describe '#removals_string' do
    subject { decorated_order_item.removals_string }
    it { should eql "Cheese, Cucumbers" }
  end
end
