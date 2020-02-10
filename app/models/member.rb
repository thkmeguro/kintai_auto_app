class Member < ActiveRecord::Base
  include EncryptionModule

  attr_accessor :decrypt_slack_authed_user_access_token, :decrypt_slack_legacy_token

  before_save :encrypt_data
  after_find :decrypt_data

  def load_encryption
    EncryptionModule::Encryption.new
  end

  def encrypt_data
    self.slack_authed_user_access_token = load_encryption.encrypt(self.slack_authed_user_access_token)
    self.slack_legacy_token = load_encryption.encrypt(self.slack_legacy_token)
  end

  def decrypt_data
    self.decrypt_slack_authed_user_access_token = load_encryption.decrypt(self.slack_authed_user_access_token) if self.slack_authed_user_access_token
    self.decrypt_slack_legacy_token = load_encryption.decrypt(self.slack_legacy_token) if self.slack_legacy_token
  end
end