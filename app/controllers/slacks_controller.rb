class SlacksController < ApplicationController
  require 'openssl'
  require 'slack-ruby-client'
  require 'json'
  include EncryptionModule

  def create
    log_url        = ENV.fetch("SLACK_LOG_POST_URL") {}
    header_options = { 'Content-type' => 'application/json' }

    data = {'text' => "#{params}"}.to_json
    Io::Api.new.request_api(log_url, data, header_options)

    is_from_slack = is_from_slack?
    # todo:ローカルのとき外す
    return unless is_from_slack

    # todo:開発用メッセージ
    judge_text = { 'text' => "#{is_from_slack ? 'From Slack!' : 'Not from Slack. Secure?'}" }.to_json
    Io::Api.new.request_api(log_url, judge_text, header_options)

    parameters = params
    type = parameters['type']
    callback_id = params['callback_id']
    command = params['command']
    text = params['text']
    user_id = params['user_id']

    if type === 'dialog_submission'
      dialog_from = callback_id.split(':')[0] # ex: create_user_data

      case dialog_from
      when 'create_user_data'
        create_user_data_by_dialog(user_id, parameters)
        render json: {'text' => '自動打刻設定を登録しました！'}, stasus: 200
      end
    elsif command == '/kintai_auto'
      # slashコマンドが着たらこちらに遷移
      trigger_id   = params['trigger_id']
      # response_url = params['response_url']

      # この時点で、showを経由してOAuth2仕様のuser_id, access_tokenが作られているとする。
      # なければ先に作るようにお願いして、URLも送る。
      user = Member.find_by(slack_authed_user_id: user_id)
      user_access_token = user.decrypt_slack_authed_user_access_token

      Slack.configure do |config|
        config.token = user_access_token
      end

      client = Slack::Web::Client.new

      case text
      when 'create'
        open_create_dialog(client, trigger_id)
        render json: {'text' => 'ダイアログを開きます'}, stasus: 200
      when 'show'
        render json: { 'text' => "#{parameters}" }, stasus: 200
      when 'disable'
        render json: { 'text' => "#{parameters}" }, stasus: 200
      when 'enable'
        render json: { 'text' => "#{parameters}" }, stasus: 200
      else
        render json: { 'text' => "キャンセルしました" }, stasus: 200
      end
    end
  end

  private

  def create_user_data_by_dialog(user_id, data)
    Member.find_or_create_by(user_id: user_id)

    mac_address_list = {
        pc_macaddress:         data['submission']['pc_macaddress'],
        smartphone_macaddress: data['submission']['smartphone_macaddress'],
        tablet_macaddress:     data['submission']['tablet_macaddress'],
        other_macaddress:      data['submission']['other_macaddress']
    }

    Device.where(user_id: user_id).map{|r| r.update!({deleted: 1})}

    mac_address_list.each do |device_type, mac_address|
      next if mac_address
      device = Device.find_or_initialize_by(user_id: user_id, mac_address: mac_address)
      device.update!({device_type: device_type, deleted: 0})
    end
  end

  def open_create_dialog(client, trigger_id)
    callback_id = "create_user_data:#{Time.current.to_i}" # slackからdialogの返答とともに返送されてくるのでvalidationできる
    data_json   = {
      'callback_id' => callback_id,
      'title' => '自動打刻設定の登録',
      'submit_label' => '登録する',
      'notify_on_cancel' => true,
      'state' => '普段ホームに持ち込む機器を登録してください！',
      'elements' => [
        {
          'type'        => 'text',
          'optional'    => false,
          'placeholder' => "ex: xoxp-...で始まる文字列",
          'label'       => 'Legacy token: ここから生成 → https://bit.ly/2tOyJK0',
          'name'        => 'slack_legacy_token'
        },
        {
          'type'        => 'text',
          'max_length'  => 17,
          'min_length'  => 17,
          'placeholder' => 'ex: 22:33:00:aa',
          'optional'    => false,
          'label'       => 'PCのMAC Address',
          'name'        => 'pc_macaddress'
        },
        {
          'type'        => 'text',
          'max_length'  => 17,
          'min_length'  => 17,
          'placeholder' => 'ex: a2:3v:00:aa',
          'optional'    => false,
          'label'       => 'スマートフォンのMAC Address',
          'name'        => 'smartphone_macaddress'
        },
        {
          'type'        => 'text',
          'max_length'  => 17,
          'min_length'  => 17,
          'placeholder' => 'ex: m2:73:50:9a',
          'optional'    => true ,
          'label'       => 'タブレットのMAC Address',
          'name'        => 'tablet_macaddress'
        },
        {
          'type'        => 'text',
          'max_length'  => 17,
          'min_length'  => 17,
          'placeholder' => 'ex: 19:dr:10:nm',
          'optional'    => true,
          'label'       => 'その他機器のMAC Address',
          'name'        => 'other_macaddress'
        }
      ]
    }.to_json

    client.dialog_open(dialog: data_json, trigger_id: trigger_id)
    # Io::Api.new.request_api(response_url, data_json, header_options)
  end

  def load_config(key, filepath)
    yml = YAML.load_file(filepath).symbolize_keys
    raise "No such file #{filepath}" if yml.blank?
    config = yml[Rails.env.to_sym]
    raise "No such environment #{Rails.env} on #{filepath}" if config.blank?
    Rails.application.config.send("#{key}=", ActiveSupport::InheritableOptions.new(config.deep_symbolize_keys))
  rescue => e
    Rails.logger.error e.message
    Rails.logger.error e.backtrace.join("\n")
  end
end
