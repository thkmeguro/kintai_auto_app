module EncryptionModule
  extend ActiveSupport::Concern

  class Encryption
    def initialize
      # load_config(:encryption, Rails.root.join('config', 'encryption.yml'))
      keyLen = ActiveSupport::MessageEncryptor.key_len(load_credential[:crypt_cipher])
      key = ActiveSupport::KeyGenerator.new(load_credential[:crypt_secret]).generate_key(load_credential[:crypt_cipher], keyLen)
      @crypt = ActiveSupport::MessageEncryptor.new(key, cipher: load_credential[:crypt_cipher], digest: 'SHA1', serializer: Marshal)
    end

    def encrypt(string)
      @crypt.encrypt_and_sign(string)
    rescue => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
    end

    def decrypt(string)
      @crypt.decrypt_and_verify(string)
    rescue => e
      Rails.logger.error e.message
      Rails.logger.error e.backtrace.join("\n")
    end

    private
    def load_credential
      case Rails.env
      when 'development'
        return Rails.application.credentials.development
      when 'test'
        return Rails.application.credentials.test
      when 'production'
        return Rails.application.credentials.production
      end
    end
    # def load_config(key, filepath)
    #   yml = YAML.load_file(filepath).symbolize_keys
    #   raise "No such file #{filepath}" if yml.blank?
    #   config = yml[Rails.env.to_sym]
    #   raise "No such environment #{Rails.env} on #{filepath}" if config.blank?
    #   Rails.application.config.send("#{key}=", ActiveSupport::InheritableOptions.new(config.deep_symbolize_keys))
    # rescue => e
    #   Rails.logger.error e.message
    #   Rails.logger.error e.backtrace.join("\n")
    # end
  end
end
