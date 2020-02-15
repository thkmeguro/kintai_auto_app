class Slacks::SlCommandsController < ApplicationController
  require 'json'

  MACHINE_MAC_ADDRESS = 'machine_mac_address'
  SP_MAC_ADDRESS      = 'smartphone_mac_address'
  TABLET_MAC_ADDRESS  = 'tablet_mac_address'
  OTHER_MAC_ADDRESS   = 'other_mac_address'

  def create
    # log_url        = ENV.fetch("SLACK_LOG_POST_URL") {}
    # header_options = { 'Content-type' => 'application/json' }
    # data = {'text' => "#{posted_params}"}.to_json
    # Io::Api.new.request_api(log_url, data, header_options)

    is_from_slack = is_from_slack?
    # todo:ローカルのとき外す
    return unless is_from_slack
    return render json: { 'text' => 'POST先を間違えています' } unless posted_params['command'] == '/kintai_auto'

    # todo:開発用メッセージ
    # judge_text = { 'text' => "#{is_from_slack ? 'From Slack!' : 'Not from Slack. Secure?'}" }.to_json
    # Io::Api.new.request_api(log_url, judge_text, header_options)

    slack_authed_user_id = posted_params['user_id']

    # この時点で、showを経由してOAuth2仕様のuser_id, access_tokenが作られているとする。
    # なければ先に作るようにお願いして、URLも送る。
    member = Member.find_by(slack_authed_user_id: slack_authed_user_id)
    return render json: { 'text' => 'user_idがありません。（URL貼り付け）からOAuth認証してください' } unless member

    decrypt_slack_authed_user_access_token = member.decrypt_slack_authed_user_access_token
    no_token_text = 'access_tokenがありません。（URL貼り付け）からOAuth認証してください'
    return render json: { 'text' => no_token_text } unless decrypt_slack_authed_user_access_token

    action_by_option(member, posted_params)
  end

  private

  def posted_params
    params.permit(:command, :user_id, :text, :trigger_id, :type)
  end

  def action_by_option(member, parameters)
    slack_authed_user_id = parameters['user_id']
    decrypt_slack_authed_user_access_token = member.decrypt_slack_authed_user_access_token
    slack = SlackClient.new(decrypt_slack_authed_user_access_token)

    case parameters['text']
    when 'create'
      trigger_id = parameters['trigger_id']
      slack.open_create_dialog(trigger_id, member)
      render json: {'text' => 'ダイアログを開きます'}, stasus: 200
    when 'show'
      member       = Member.fetch_active_member(slack_authed_user_id: slack_authed_user_id)
      p devices      = Device.fetch_user_mac_addresses(slack_authed_user_id: slack_authed_user_id)
      legacy_token = member.decrypt_slack_legacy_token

      text = " :speaking_head_in_silhouette: 登録状況を表示します\n\n" +
          '```' +
          "【Legacy_token】：#{legacy_token ? "#{legacy_token[0..6]}**********#{legacy_token[-2..-1]}" : '未登録'}\n" +
          "【#{MACHINE_MAC_ADDRESS}】: #{devices[MACHINE_MAC_ADDRESS] || '登録なし'}\n" +
          "【#{SP_MAC_ADDRESS}】: #{devices[SP_MAC_ADDRESS] || '登録なし'}\n" +
          "【#{TABLET_MAC_ADDRESS}】: #{devices[TABLET_MAC_ADDRESS] || '登録なし'}\n" +
          "【#{OTHER_MAC_ADDRESS}】: #{devices[OTHER_MAC_ADDRESS] || '登録なし'}" +
          "```\n\n" +
          "設定は#{member ? '有効 :zap: ' : '「無効」 :ballot_box_with_check: '}です！"

      render json: { 'text' => "#{text}" }, stasus: 200
    when 'disable'
      member = Member.fetch_active_member(slack_authed_user_id: slack_authed_user_id)

      if member
        member.change_to_disable
        text = "自動打刻設定をOFFにしました！\n" +
            "enableコマンドで直前の設定が復活できます"
        render json: { 'text' => text }, stasus: 200
      else
        render json: { 'text' => '有効な設定がありませんでした' }, stasus: 200
      end
    when 'enable'
      member = Member.fetch_not_active_latest_member(slack_authed_user_id: slack_authed_user_id)

      if member
        member.change_to_enable
        text = "自動打刻設定をONにしました！\n" +
            "設定内容はshowで確認してください\n" +
            "設定内容の編集はcreateから行ってください"
        render json: { 'text' => text }, stasus: 200
      else
        render json: { 'text' => '失効中の設定がありませんでした' }, stasus: 200
      end
    else
      render json: { 'text' => "オプションが空欄か、スペルが間違っているかもしれません :cloud: " }, stasus: 200
    end
  end
end
