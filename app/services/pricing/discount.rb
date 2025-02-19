module Pricing
  module Discount
    DISCOUNT_CALCULATORS = {
      "SAVE5" => Pricing::SaveXDiscount
    }.freeze

    class << self
      def price_discount(price, discount_codes)
        discount_codes.map { price_discount_code(price, _1) }.sum
      end

      private

      def price_discount_code(price, code_name)
        discount_calculator = DISCOUNT_CALCULATORS[code_name]
        options = Configuration.instance.discount_options(code_name)

        discount_calculator.run(price, options)
      end
    end
  end
end
