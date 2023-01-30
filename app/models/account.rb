class Account < ApplicationRecord
  has_many :messages, dependent: :destroy
end
