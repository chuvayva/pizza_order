Money.default_currency = Money::Currency.new("EUR")
Money.rounding_mode = BigDecimal::ROUND_HALF_UP
Money.locale_backend = :i18n
