module CommonModel
  def load_encryption
    EncryptionModule::Encryption.new
  end
end