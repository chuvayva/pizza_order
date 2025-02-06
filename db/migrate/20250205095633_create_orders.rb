class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :orders do |t|
      t.uuid   :public_id, null: false, default: -> { "gen_random_uuid()" }
      t.string :state, default: :open
      t.text :promotion_codes, array: true, default: []
      t.text :discount_codes, array: true, default: []

      t.timestamps
    end

    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.string :name
      t.string :size
      t.text :addons, array: true, default: []
      t.text :removals, array: true, default: []

      t.timestamps
    end
  end
end
