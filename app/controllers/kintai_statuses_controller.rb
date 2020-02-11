class KintaiStatusesController < ApplicationController
  # IoTなど対象じゃないMACアドレスを記載
  REMOVE_LIST = []

  def create
    login_mac_address_list = posted_params[:mac_address_list].split(',')
    machine_mac_addresses = login_mac_address_list - REMOVE_LIST
    not_yet_login_members = Member.active.not_login
    active_devices = Device.active.group_by{ |r| r.slack_authed_user_id }

    not_yet_login_members.each do |member|
      member_devices = active_devices[member.slack_authed_user_id]
      device_mac_address_list = member_devices.map{|r| r.decrypt_mac_address}
      is_online = device_mac_address_list.size != (device_mac_address_list.size - machine_mac_addresses.size)

      if is_online
        member.update_with_token!(attr: {has_connected_today: 1}, slack_authed_user_access_token: nil, slack_legacy_token: nil)
        exec_jobcan_touch(member)
      end
      # todo テストでは、フラグをすぐ消す、本番は0時に更新する
      member.update_with_token!(attr: {has_connected_today: 0}, slack_authed_user_access_token: nil, slack_legacy_token: nil)
    end

    render json: {'text' => '正常に受け取りました'}, stasus: 200
  end

  private

  def posted_params
    params.permit(:mac_address_list)
  end

  def exec_jobcan_touch(member)
    user_id       = member.slack_authed_user_id
    access_token  = member.slack_authed_user_access_token
    legacy_token  = member.slack_legacy_token
    client_latest = SlackClient.new(access_token, user_id)
    client_legacy = SlackClient.new(legacy_token, user_id)

    client_latest.is_user_id_valid?
    client_legacy.check_work_status # legacy
    today_whole_working_statuses = client_latest.fetch_todays_jobcan_mss
    client_legacy.kintai_start_when_not(today_whole_working_statuses) # legacy
  end
end
