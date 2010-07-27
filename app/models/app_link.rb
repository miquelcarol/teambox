class AppLink < ActiveRecord::Base

  belongs_to :user
  validates_uniqueness_of :app_user_id, :scope => :provider
  validates_uniqueness_of :user_id, :scope => :provider

  def self.providers
    Array(APP_CONFIG['oauth_providers']).collect { |key,provider| provider['name'] }  +
    Array(APP_CONFIG['openid_providers']).collect { |key,provider| provider['name'] }
  end

end
