module Pricing
  module NForMPromotion
    def self.run(order, options)
      target = options["target"]
      target_size = options["target_size"]
      from = options["from"]
      to = options["to"]

      target_count = order.order_items.count { _1.name == target && _1.size == target_size }
      complete_groups = target_count / from
      free_pizzas = complete_groups * (from - to)

      Pricing::Calculator.pizza_price(target, target_size) * free_pizzas
    end
  end
end
