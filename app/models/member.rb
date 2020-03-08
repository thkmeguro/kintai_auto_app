class Member < ActiveRecord::Base
  include CommonModel
  # has_many :devices

  attr_accessor :decrypt_slack_authed_user_access_token, :decrypt_slack_legacy_token

  before_save :encrypt_data
  after_find :decrypt_data

  NOT_DELETED = NOT_ACTIVE = false
  DELETED = true

  scope :active, -> { where(deleted: [nil, NOT_DELETED]) }
  scope :not_active, -> { where(deleted: DELETED) }
  scope :login, -> { where(has_connected_today: true) }
  scope :not_login, -> { where(has_connected_today: [nil, NOT_ACTIVE]) }

  def encrypt_data
    self.slack_authed_user_access_token = load_encryption.encrypt(self.slack_authed_user_access_token)
    self.slack_legacy_token = load_encryption.encrypt(self.slack_legacy_token)
  end

  def decrypt_data
    self.decrypt_slack_authed_user_access_token = load_encryption.decrypt(self.slack_authed_user_access_token) if self.slack_authed_user_access_token
    self.decrypt_slack_legacy_token = load_encryption.decrypt(self.slack_legacy_token) if self.slack_legacy_token
  end

  def self.fetch_active_member(slack_authed_user_id:)
    active.find_by(slack_authed_user_id: slack_authed_user_id)
  end

  def self.fetch_not_active_latest_member(slack_authed_user_id:)
    not_active.where(slack_authed_user_id: slack_authed_user_id).last
  end

  def self.fetch_not_online_member(slack_authed_user_id:)
    m = active.not_login.find_by(slack_authed_user_id: slack_authed_user_id)
    m.blank? ? nil : m
  end

  def self.fetch_online_members
    active.login
  end

  def self.find_or_create_member(user_id:, access_token:)
    member = find_or_initialize_by(slack_authed_user_id: user_id)
    member.update_with_token!(attr: { slack_authed_user_access_token: access_token })
  end

  def change_to_disable
    update_with_token!(attr: {deleted: DELETED})
  end

  def change_to_enable
    update_with_token!
  end

  def update_with_token!(attr: {})
    attr[:slack_authed_user_access_token] ||= self.decrypt_slack_authed_user_access_token
    attr[:slack_legacy_token] ||= self.decrypt_slack_legacy_token
    attr[:deleted] ||= false
    update!(attr)
  end

  private

  # activerecord/lib/active_record/persistence.rb
  # updateをオーバーライドしてmodel内でのみ使用できるようにする
  def update!(attr)
    self.update_attributes!(attr)
  end

  def update(attr)
    self.update_attributes(attr)
  end
end