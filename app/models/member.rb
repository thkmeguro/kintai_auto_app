class Member < ActiveRecord::Base
  include CommonModel

  attr_accessor :decrypt_slack_authed_user_access_token, :decrypt_slack_legacy_token

  before_save :encrypt_data
  after_find :decrypt_data

  NOT_DELETED = NOT_ACTIVE = '0'

  scope :active, -> { where(deleted: NOT_DELETED) }
  scope :not_login, -> { where(has_connected_today: [nil, NOT_ACTIVE]) }

  def encrypt_data
    self.slack_authed_user_access_token = load_encryption.encrypt(self.slack_authed_user_access_token)
    self.slack_legacy_token = load_encryption.encrypt(self.slack_legacy_token)
  end

  def decrypt_data
    self.decrypt_slack_authed_user_access_token = load_encryption.decrypt(self.slack_authed_user_access_token) if self.slack_authed_user_access_token
    self.decrypt_slack_legacy_token = load_encryption.decrypt(self.slack_legacy_token) if self.slack_legacy_token
  end

  def self.fetch_member(slack_authed_user_id)
    active.find_by(slack_authed_user_id: slack_authed_user_id)
  end

  def update_with_token!(attr:, slack_authed_user_access_token:, slack_legacy_token:)
    attr[:slack_authed_user_access_token] = self.decrypt_slack_authed_user_access_token unless slack_authed_user_access_token
    attr[:slack_legacy_token] = self.decrypt_slack_legacy_token unless slack_legacy_token
    update!(attr)
  end
end