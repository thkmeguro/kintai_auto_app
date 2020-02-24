class Oauths::LandingsController < ApplicationController
  OAUTH_STATE = 'from-tm-sending'

  def show
    base_url     = 'https://slack.com/oauth/v2/authorize'
    client_id    = "client_id=#{ENV.fetch('SLACK_CLIENT_ID') {}}"
    scope        = "scope=#{SCOPE}"
    user_scope   = "user_scope=#{USER_SCOPE}"
    state        = "state=#{OAUTH_STATE}"
    redirect_url = "redirect_url=#{ENV.fetch('REDIRECT_URL_REGISTER') {}}"

    @oauth_url = base_url + '?' +
        client_id + '&' +
        scope + '&' +
        user_scope + '&' +
        state + '&' +
        redirect_url
  end
end