class User < ApplicationRecord
  # associations
  has_many :sessions
  has_many :tweets

  # validations
  validates :username, presence: true, length: { minimum: 3, maximum: 64 }
  validates :password, presence: true, length: { minimum: 8, maximum: 64 }
  validates :email, presence: true, length: { minimum: 5, maximum: 500 }

  validates_uniqueness_of :username
  validates_uniqueness_of :email

  after_validation :hash_password

  # custom methods
  # check rate limit: user.tweets count in past 60 mins should be < 30 to allow new tweet
  def pass_rate_limit?
    self.tweets.where('created_at > ?', Time.now - 60.minutes).count < 30
  end

  private

  def hash_password
    self.password = BCrypt::Password.create(password)
  end
end
