class Tweet < ApplicationRecord
  # associations
  belongs_to :user
  has_one_attached :image

  # validations
  validates :user, presence: true
  validates :message, presence: true, length: { maximum: 140 }
end
