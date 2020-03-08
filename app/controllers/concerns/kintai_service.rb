class KintaiService
  # IoTなど対象じゃないMACアドレスを記載
  REMOVE_LIST = []

  def initialize(login_mac_addresses)
    @login_mac_addresses = login_mac_addresses
  end

  def execute_jobcan
    retrieve_login_members_user_ids.each do |user_id|
      if member = Member.fetch_not_online_member(slack_authed_user_id: user_id)
        begin
          exec_jobcan_touch!(member)
          member.update_with_token!(attr: { has_connected_today: true })
        rescue => e
          Rails.logger.error e.message
          next
        end
      end
    end
  end

  def reset_login_flg
    # 朝方にフラグを戻す
    if is_reset_time?
      members = Member.fetch_online_members
      members.each { |m| m.update_with_token!(attr: { has_connected_today: false }) }
    end
  end

  private

  def retrieve_valid_mac_addresses
    @login_mac_addresses - REMOVE_LIST
  end

  def retrieve_login_members_user_ids
    valid_mac_addresses = retrieve_valid_mac_addresses
    valid_machine_and_user_id = Device.fetch_mac_addresses_and_user_id
    valid_mac_addresses.map { |mac_address| valid_machine_and_user_id[mac_address] }.uniq.compact
  end

  # 失敗したら例外処理
  def exec_jobcan_touch!(member)
    user_id       = member.slack_authed_user_id
    access_token  = member.slack_authed_user_access_token
    legacy_token  = member.slack_legacy_token

    client_latest = slack_client(access_token, user_id)
    client_legacy = slack_client(legacy_token, user_id)

    client_latest.is_user_id_valid?
    client_legacy.check_and_post_work_status # legacy
    today_whole_working_statuses = client_latest.fetch_todays_jobcan_mss
    client_legacy.kintai_start_when_not(today_whole_working_statuses) # legacy
  end

  def is_reset_time?
    Time.current.beginning_of_day < Time.current && Time.current < Time.parse('5:00')
  end

  def slack_client(token, user_id)
    SlackClient.new(token, user_id)
  end
end