class GetMercadoPagoPayer
  def self.call(user_id)
    new(user_id).call
  end

  def initialize(user_id)
    @user_id = user_id
  end

  def call
    user = Spree::User.find(@user_id)
    payment_method = Spree::PaymentMethod.find_by_type("Spree::PaymentMethod::MercadoPago")
    return { customer_id: '', cards: [] } unless payment_method

    sdk = Mercadopago::SDK.new(payment_method.preferred_access_token || '')
    customers_response = sdk.customer.search(filters: { email: user.email })&.dig(:response)&.dig("results")&.first
    customer_id = customers_response&.dig("id")
    unless customer_id
      customer_response = sdk.customer.create({ email: user.email })
      customer_id = customer_response[:response]&.dig("id")
    end

    cards_response = []
    if customer_id
      cards_response = sdk.card.list(customer_id)&.dig(:response)
    end

    {
      customer_id: customer_id,
      cards: cards_response.map{ |card| card.dig("id") }
    }
  end
end