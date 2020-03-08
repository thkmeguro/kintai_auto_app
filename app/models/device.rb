class Device < ActiveRecord::Base
  include CommonModel
  # belongs_to :user

  attr_accessor :decrypt_mac_address

  before_save :encrypt_data
  after_find :decrypt_data

  NOT_DELETED = false
  DELETED     = true

  scope :active, -> { where(deleted: [nil, NOT_DELETED]) }

  def encrypt_data
    # downcaseに統一
    self.mac_address = load_encryption.encrypt(self.mac_address.downcase)
  end

  def decrypt_data
    self.decrypt_mac_address = load_encryption.decrypt(self.mac_address) if self.mac_address
  end

  def self.delete_current_settings(slack_authed_user_id:)
    active.where(slack_authed_user_id: slack_authed_user_id)
        .map { |r| r.update_with_mac_address!(attr: { deleted: DELETED }) }
  end

  def self.fetch_user_mac_addresses(slack_authed_user_id:)
    # pluck使いたいけどmac_addressはエンクリプトしていて直接引けない
    data = active.where(slack_authed_user_id: slack_authed_user_id)
    data.inject({}) { |r, i| r[i.device_type] = i.decrypt_mac_address ; r }
  end

  def self.fetch_mac_addresses_and_user_id
    # pluck使いたいけどmac_addressはエンクリプトしていて直接引けない
    active.inject({}) { |r, i| r[i.decrypt_mac_address] = i.slack_authed_user_id ; r }
  end

  def update_with_mac_address!(attr: {})
    attr[:mac_address] ||= self.decrypt_mac_address
    attr[:deleted] ||= true
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