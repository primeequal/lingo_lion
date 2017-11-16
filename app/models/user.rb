class User < ApplicationRecord
  devise :omniauthable, :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :omniauth_providers => [:google_oauth2]

  attr_accessor :provider, :uid

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_initialize.tap do |user|
      user.provider = auth.provider
      user.uid = auth.uid
      user.name = auth.info.name
      user.oauth_token = auth.credentials.token
      user.oauth_expires_at = Time.at(auth.credentials.expires_at)
      user.save!
    end
  end

  def self.find_for_google_oauth2(access_token, signed_in_resource=nil)
    data = access_token.info
    user = User.where(:email => data['email']).first

    unless user
      user = User.create(
          :email => data['email'],
          :password => Devise.friendly_token[0, 20]
      )
    end
    user
  end
end
