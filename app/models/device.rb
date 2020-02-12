class Device < ActiveRecord::Base
  include CommonModel

  attr_accessor :decrypt_mac_address

  before_save :encrypt_data
  after_find :decrypt_data

  NOT_DELETED = 0
  DELETED     = 1

  scope :active, -> { where(deleted: NOT_DELETED) }

  def encrypt_data
    self.mac_address = load_encryption.encrypt(self.mac_address)
  end

  def decrypt_data
    self.decrypt_mac_address = load_encryption.decrypt(self.mac_address) if self.mac_address
  end

  def self.delete_current_settings(slack_authed_user_id:)
    active.where(slack_authed_user_id: slack_authed_user_id)
        .map { |r| r.update_with_mac_address!(attr: {deleted: DELETED}, mac_address: nil) }
  end

  def self.fetch_user_mac_addresses(slack_authed_user_id:)
    # pluck使いたいけどmac_addressはエンクリプトしていて直接引けない
    data = active.where(slack_authed_user_id: slack_authed_user_id)
    data.inject({}) { |r, i| r[i.device_type] = i.decrypt_mac_address }
  end

  def update_with_mac_address!(attr:, mac_address:)
    attr[:mac_address] = self.decrypt_mac_address unless mac_address
    update!(attr)
  end
end