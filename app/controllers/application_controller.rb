class ApplicationController < ActionController::Base
  protect_from_forgery

  def is_from_slack?
    version_num  = 'v0'
    timestamp    = request.headers['X-Slack-Request-Timestamp']
    request_body = request.body.read

    sig_basestring = "#{version_num}:#{timestamp}:#{request_body}"
    secret_key     = ENV.fetch("SLACK_SIGNING_SECRET") {}
    my_signature   = 'v0=' + OpenSSL::HMAC.hexdigest('sha256', secret_key, sig_basestring)

    signature_slack = request.headers['X-Slack-Signature']
    return (my_signature == signature_slack)
  end
end
