def encrypt_string(string, password)
  key   = OpenSSL::Digest::SHA256.digest(password)
  cipher = OpenSSL::Cipher.new('AES-256-CBC')
  cipher.encrypt
  cipher.key = key
  encrypted_data = cipher.update(string) + cipher.final
  Base64.strict_encode64(encrypted_data)
end

def decrypt_string(encrypted_string, password)
  encrypted_data = Base64.strict_decode64(encrypted_string)
  key   = OpenSSL::Digest::SHA256.digest(password)
  cipher = OpenSSL::Cipher.new('AES-256-CBC')
  cipher.decrypt
  cipher.key = key
  decrypted_data = cipher.update(encrypted_data) + cipher.final
  decrypted_data
end