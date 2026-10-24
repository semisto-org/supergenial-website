class Session < ApplicationRecord
  skip_audit

  LIFETIME = 30.days

  belongs_to :user

  scope :alive, -> { where(created_at: LIFETIME.ago..) }
end
