class RegistersController < ApplicationController
  require 'slack-ruby-client'
  include EncryptionModule

  def show
    is_from_slack = is_from_slack?
    # todo:ローカルのとき外す
    return unless is_from_slack

    # Instantiate a web client
    client = Slack::Web::Client.new
    client_id = ENV['SLACK_CLIENT_ID']
    scope = 'incoming-webhook,commands'
    redirect_url = ENV['REDIRECT_URL'] + '?scope=' + scope + '&client_id=' + client_id

    # Request a token using the temporary code
    rc = client.oauth_v2_access(
      client_id: client_id,
      client_secret: ENV['SLACK_CLIENT_SECRET'],
      code: params[:code],
      redirect_url: redirect_url
    )

    # Pluck the token from the response
    user_id = rc['authed_user']['id']
    access_token  = rc['authed_user']['access_token']

    member = Member.find_or_initialize_by(slack_authed_user_id: user_id)
    member.update_with_token!(attr: {}, slack_authed_user_access_token: access_token, slack_legacy_token: nil)
  end
end