module Pricing
  module SaveXDiscount
    def self.run(price, options)
      price * options["deduction_in_percent"] / 100
    end
  end
end
