class Transaction < ApplicationRecord
  belongs_to :user
  belongs_to :tournament, optional: true

  enum transaction_type: {deposit: 0, withdraw: 1, buyIn: 2, cash: 3, premium_withdraw: 4, prize_money: 5}
  enum transaction_source: {paypal: 0}
end
