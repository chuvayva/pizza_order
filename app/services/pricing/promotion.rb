module Pricing
  module Promotion
    PROMOTION_CALCULATORS = {
      "2FOR1" => Pricing::NForMPromotion
    }.freeze

    class << self
      def promotion_discount(order)
        order.promotion_codes.map { promotion_discount_code(order, _1) }.sum
      end

      private

      def promotion_discount_code(order, code_name)
        promotion_calculator = PROMOTION_CALCULATORS[code_name]
        options = Configuration.instance.promotion_options(code_name)

        promotion_calculator.run(order, options)
      end
    end
  end
end
