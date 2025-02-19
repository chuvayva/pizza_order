module Pricing
  module NForMPromotion
    def self.run(order, options)
      target = options["target"]
      target_size = options["target_size"]

      target_count = order.order_items.count { _1.name == target && _1.size == target_size }

      price = Pricing::Calculator.pizza_price(target, target_size)
      price * target_count * options["to"] / options["from"]
    end
  end
end
