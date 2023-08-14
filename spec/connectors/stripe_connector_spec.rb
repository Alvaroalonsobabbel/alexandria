require 'rails_helper'

RSpec.describe StripeConnector do
  before(:all) { Stripe.api_key ||= ENV['STRIPE_API_KEY'] }

  let(:book) { create(:book, price_cents: 299) }
  let(:purchase) { create(:purchase, book: book) }

  def charge_with_token(purchase, token)
    purchase.update_column :token, token
    StripeConnector.new(purchase).send(:create_charge)
  end

  context 'with valid card' do
    let(:valid_token) { 'tok_visa' }

    it 'succeeds' do
      VCR.use_cassette('stripe/valid_card') do
        charge = charge_with_token(purchase, valid_token)

        expect(charge['status']).to eq 'succeeded'
        expect(purchase.reload.charge_id).to eq charge['id']
        expect(purchase.reload.status).to eq 'confirmed'
      end
    end
  end

  context 'with invalid card' do
    let(:invalid_token) { 'tok_visa_chargeDeclined' }

    it 'declines the card' do
      VCR.use_cassette('stripe/invalid_card') do
        charge = charge_with_token(purchase, invalid_token)

        expect(charge[:error][:code]).to eq 'card_declined'
        expect(purchase.reload.error).to eq charge[:error].stringify_keys
        expect(purchase.reload.status).to eq 'rejected'
      end
    end
  end
end
