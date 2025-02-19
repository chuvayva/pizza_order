FactoryBot.define do
  factory :order do
    trait :simple do
      after(:create) do |order|
        create(:order_item, name: "Tonno", size: "Large", order:)
      end
    end

    trait :with_addons do
      after(:create) do |order|
        create(:order_item, name: "Margherita", size: "Large", addons: [ "Onions", "Cheese", "Olives" ], order:)
      end
    end

    trait :with_removals do
      after(:create) do |order|
        create(:order_item, name: "Margherita", size: "Large", removals: [ "Onions", "Cheese", "Olives" ], order:)
      end
    end

    trait :with_discount do
      discount_codes { [ "SAVE5" ] }

      after(:create) do |order|
        create(:order_item, name: "Salami", size: "Medium", order:)
        create(:order_item, name: "Salami", size: "Small", order:)
      end
    end

    trait :with_promotion do
      discount_codes { [ "SAVE5" ] }
      promotion_codes { [ "2FOR1" ] }

      after(:create) do |order|
        create(:order_item, name: "Salami", size: "Medium", addons: [ "Onions" ], removals: [ "Cheese" ], order:)
        create(:order_item, name: "Salami", size: "Small", order:)
        create(:order_item, name: "Salami", size: "Small", order:)
        create(:order_item, name: "Salami", size: "Small", order:)
        create(:order_item, name: "Salami", size: "Small", addons: [ "Olives" ], order:)
      end
    end
  end
end
