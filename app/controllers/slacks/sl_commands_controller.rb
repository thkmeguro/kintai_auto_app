class Slacks::SlCommandsController < ApplicationController
  require 'json'

  def create
    log_url        = ENV.fetch("SLACK_LOG_POST_URL") {}
    header_options = { 'Content-type' => 'application/json' }
    parameters     = params

    data = {'text' => "#{parameters}"}.to_json
    Io::Api.new.request_api(log_url, data, header_options)

    is_from_slack = is_from_slack?
    # todo:ローカルのとき外す
    return unless is_from_slack

    # todo:開発用メッセージ
    judge_text = { 'text' => "#{is_from_slack ? 'From Slack!' : 'Not from Slack. Secure?'}" }.to_json
    Io::Api.new.request_api(log_url, judge_text, header_options)

    # type        = parameters['type']
    # callback_id = parameters['callback_id']
    command     = parameters['command']
    text        = parameters['text']
    slack_authed_user_id     = parameters['user_id']

    if command == '/kintai_auto'
      trigger_id   = parameters['trigger_id']
      # response_url = parameters['response_url']

      # この時点で、showを経由してOAuth2仕様のuser_id, access_tokenが作られているとする。
      # なければ先に作るようにお願いして、URLも送る。
      member = Member.find_by(slack_authed_user_id: slack_authed_user_id)
      decrypt_slack_authed_user_access_token = member.decrypt_slack_authed_user_access_token
      slack = SlackClient.new(decrypt_slack_authed_user_access_token)

      case text
      when 'create'
        slack.open_create_dialog(trigger_id, member)
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

  def posted_params
    params.permit!(:type, :callback_id, :command, :text, :user_id)
  end
end
