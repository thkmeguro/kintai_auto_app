class Slacks::IrMessagesController < ApplicationController
  require 'slack-ruby-client'
  require 'json'

  SLACK_LEGACY_TOKEN  = 'slack_legacy_token'
  MACHINE_MAC_ADDRESS = 'machine_mac_address'
  SP_MAC_ADDRESS      = 'smartphone_mac_address'
  TABLET_MAC_ADDRESS  = 'tablet_mac_address'
  OTHER_MAC_ADDRESS   = 'other_mac_address'
  DATA_SUBMISSION     = 'dialog_submission'
  DIALOG_CREATE_USER  = 'create_user_data'

  def create
    is_from_slack = is_from_slack?

    return unless is_from_slack

    payload              = JSON.parse(dialog_param['payload'])
    type                 = payload['type']
    slack_authed_user_id = payload['user']['id']
    state                = payload['state'] # ex: create_user_data

    if type === DATA_SUBMISSION
      case state
      when DIALOG_CREATE_USER
        create_user(slack_authed_user_id, payload)
        return render json: {}, stasus: 200
      else
        Rails.logger.error "#{slack_authed_user_id}: ダイアログからの登録に失敗しました"
        return render json: {}, stasus: 200
      end
    end
  end

  private

  def dialog_param
    params.permit(:payload)
  end

  def create_user(slack_authed_user_id, payload)
    member = Member.fetch_active_member(slack_authed_user_id: slack_authed_user_id)

    return unless decrypt_access_token = member.decrypt_slack_authed_user_access_token

    Rails.logger.info text = create_user_data_by_dialog(member, slack_authed_user_id, payload)
    bot_token = ENV.fetch('SLACK_BOT_TOKEN') {}

    raise 'SLACK_BOT_TOKENが空欄です' if bot_token.blank?

    # todo slackclientに寄せる
    slack      = SlackClient.new(decrypt_access_token, slack_authed_user_id)
    channel_id = payload['channel']['id']
    slack.chat_post_ephemeral(text, channel_id)
  end

  def create_user_data_by_dialog(member, slack_authed_user_id, payload)
    validate_data(payload)

    # member = Member.find_or_initialize_by(slack_authed_user_id: slack_authed_user_id)
    slack_legacy_token = payload['submission'][SLACK_LEGACY_TOKEN]

    member.update_with_token!(attr: { slack_legacy_token: slack_legacy_token })
    member.decrypt_slack_authed_user_access_token

    mac_address_list = {
      MACHINE_MAC_ADDRESS => payload['submission'][MACHINE_MAC_ADDRESS],
      SP_MAC_ADDRESS      => payload['submission'][SP_MAC_ADDRESS],
      TABLET_MAC_ADDRESS  => payload['submission'][TABLET_MAC_ADDRESS],
      OTHER_MAC_ADDRESS   => payload['submission'][OTHER_MAC_ADDRESS]
    }

    # 一度設定を消す
    Device.delete_current_settings(slack_authed_user_id: slack_authed_user_id)

    mac_address_list.each do |device_type, mac_address|
      next unless mac_address
      device = Device.find_or_initialize_by({
                                                slack_authed_user_id: slack_authed_user_id,
                                                device_type: device_type
                                            })
      device.update_with_mac_address!(attr: { mac_address: mac_address })
    end

    return 'フォームの情報を元に、自動打刻設定を登録しました！（※ 退勤はまだ打刻できませんm(_ _)m）'
  rescue => e
    Rails.logger.error e.message
    e.message
  end

  def validate_data(payload)
    text = ''

    if payload['submission'][SLACK_LEGACY_TOKEN]
      is_valid_legacy_token = /xoxp\-\d{12}\-\d{12}\-\d{12}\-[0-9a-f]{32}/ =~ payload['submission'][SLACK_LEGACY_TOKEN]
      text += "legacy_tokenの値が正しくない可能性があります\n" unless is_valid_legacy_token
    end

    if payload['submission'][MACHINE_MAC_ADDRESS]
      is_valid_machine_mac_address = /[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}/ =~ payload['submission'][MACHINE_MAC_ADDRESS]
      text += "MACHINE_MAC_ADDRESSの値が正しくない可能性があります\n" unless is_valid_machine_mac_address
    end

    if payload['submission'][SP_MAC_ADDRESS]
      is_valid_sp_mac_address = /[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}/ =~ payload['submission'][SP_MAC_ADDRESS]
      text += "SP_MAC_ADDRESSの値が正しくない可能性があります\n" unless is_valid_sp_mac_address
    end

    if payload['submission'][TABLET_MAC_ADDRESS]
      is_valid_tablet_mac_address = /[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}/ =~ payload['submission'][TABLET_MAC_ADDRESS]
      text += "TABLET_MAC_ADDRESSの値が正しくない可能性があります\n" unless is_valid_tablet_mac_address
    end

    if payload['submission'][OTHER_MAC_ADDRESS]
      is_valid_other_mac_address = /[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}\:[0-9a-f]{2}/ =~ payload['submission'][OTHER_MAC_ADDRESS]
      text += "OTHER_MAC_ADDRESSの値が正しくない可能性があります\n" unless is_valid_other_mac_address
    end

    raise text unless text.blank?
  end
end
