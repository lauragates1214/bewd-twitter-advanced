class Tweet < ApplicationRecord
  # associations
  belongs_to :user
  has_one_attached :image

  # validations
  validates :user, presence: true
  validates :message, presence: true, length: { maximum: 140 }

  after_create :notify_via_email

  # custom methods
  # invoke TweetMailer to send the email when a tweet is successfully posted
  private

  def notify_via_email
    TweetMailer.notify(self).deliver!
  end
end
