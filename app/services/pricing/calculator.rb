module Pricing
  module Calculator
    class << self
      def total_price(order)
        price = order.order_items.map { pizza_price(_1.name, _1.size) }.sum
        addons_price = order.order_items.map { addons_price(_1) }.sum
        promotion_discount = Pricing::Promotion.promotion_discount(order)
        subtotal = price  + addons_price - promotion_discount

        discount = Pricing::Discount.price_discount(subtotal, order.discount_codes)

        subtotal - discount
      end

      def pizza_price(name, size)
        basic_price = config.pizza_price(name)
        basic_price_money = Money.from_amount(basic_price)
        multiplier = config.size_multiplier(size)

        basic_price_money * multiplier
      end

      private

      def addons_price(order_item)
        addons_price = order_item.addons.map {
          value = config.addon_price(_1)
          Money.from_amount(value)
        }.sum
        multiplier = config.size_multiplier(order_item.size)

        addons_price * multiplier
      end

      def config
        Configuration.instance
      end
    end
  end
end
