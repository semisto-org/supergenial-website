# A remark left on any record, mostly by the accountant (who can comment but not edit).
class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :user, default: -> { Current.user }

  validates :body, presence: true

  scope :chronological, -> { order(:created_at) }
  scope :open, -> { where(resolved_at: nil) }

  def resolved? = resolved_at.present?

  def to_s = body.truncate(60)
end
