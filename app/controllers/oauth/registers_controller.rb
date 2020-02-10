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

    # secret = ENV.fetch('SECRET_ENCRYPT_KEY') {}
    # crypt = ActiveSupport::MessageEncryptor.new(secret)
    # encrypted_access_token = crypt.encrypt_and_sign(access_token)

    # exp
    # load_config(:encryption, Rails.root.join('config', 'encryption.yml'))
    # key_len = ActiveSupport::MessageEncryptor.key_len(Rails.application.config.encryption.crypt_cipher)
    # key = ActiveSupport::KeyGenerator.new(Rails.application.config.encryption.crypt_secret).generate_key(Rails.application.config.encryption.crypt_cipher, key_len)
    # crypt = ActiveSupport::MessageEncryptor.new(key, cipher: Rails.application.config.encryption.crypt_cipher, digest: 'SHA1', serializer: Marshal)
    # encrypted_access_token = crypt.encrypt_and_sign(access_token)

    # encrypted_access_token = EncryptionModule::Encryption.new.encrypt(access_token)
    # exp fin

    Member.find_or_create_by(slack_authed_user_id: user_id).update!(slack_authed_user_access_token: access_token)
  end
end