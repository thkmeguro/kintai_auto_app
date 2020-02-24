class Oauths::RegistersController < ApplicationController
  require 'slack-ruby-client'
  include EncryptionModule

  OAUTH_STATE = 'from-tm-sending'

  def show
    logger

    @result_text = ''
    @result_text += 'データが不正です' if parameters['state'] != OAUTH_STATE

    slack_client = SlackClient.new
    response = slack_client.exec_oauth_v2_access(parameters['code'])

    return @result_text += 'authed_userの情報がないです' unless response['authed_user']

    find_or_create_member(response)

    @result_text += '登録完了しました！'
  end

  private

  def parameters
    params.permit(:code, :state)
  end

  def logger
    Rails.logger.info request.headers
    Rails.logger.info parameters
  end

  def find_or_create_member(response)
    Member.find_or_create_member(
        user_id: response['authed_user']['id'],
        access_token: response['authed_user']['access_token']
    )
  end
end