class User < ApplicationRecord
  has_secure_password
  belongs_to :company
  belongs_to :market, optional: true

  validates :email, presence: true, uniqueness: { scope: :company_id }, 
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 6 }, if: -> { new_record? || !password.nil? }

  enum :role, { user: 0, admin: 1 }

  has_one_attached :profile_picture

  def display_name
    email.split('@').first.titleize
  end

  def profile_picture_url
    profile_picture.attached? ? Rails.application.routes.url_helpers.url_for(profile_picture) : nil
  end
end
