Order.where(public_id: "316c6832-e038-4599-bc32-2b0bf1b9f1c1").first_or_create!(
  order_items: [
    OrderItem.create(name: 'Tonno', size: 'Large')
  ]
)

Order.where(public_id: "f40d59d0-48bd-409a-ac7b-54a1b47f6680").first_or_create!(
  order_items: [
    OrderItem.create(name: 'Margherita', size: 'Large', addons: [ "Onions", "Cheese", "Olives" ]),
    OrderItem.create(name: 'Tonno', size: 'Medium', removals: [ "Onions", "Olives" ]),
    OrderItem.create(name: 'Margherita', size: 'Small')
  ]
)

Order.where(public_id: "9232679d-e3fd-40bd-81f4-7114ea96e420").first_or_create!(
  order_items: [
    OrderItem.create(name: 'Salami', size: 'Medium', addons: [ "Onions" ], removals: [ "Cheese" ]),
    OrderItem.create(name: 'Salami', size: 'Small'),
    OrderItem.create(name: 'Salami', size: 'Small'),
    OrderItem.create(name: 'Salami', size: 'Small'),
    OrderItem.create(name: 'Salami', size: 'Small', addons: [ "Olives" ])
  ],
  promotion_codes: [ "2FOR1" ],
  discount_codes: [ "SAVE5" ]
)
