class Configuration
  CONFIG_PATH = "config/data/config.yaml"

  include Singleton

  def initialize
    config_file_path = Rails.root.join(CONFIG_PATH)
    @config = YAML.load_file(config_file_path)
  end

  def pizza_price(name)
    @config.dig("pizzas", name)
  end

  def addon_price(name)
    @config.dig("ingredients", name)
  end

  def size_multiplier(name)
    @config.dig("size_multipliers", name)
  end

  def discount_options(name)
    @config.dig("discounts", name)
  end

  def promotion_options(name)
    @config.dig("promotions", name)
  end
end
