module Yodlee
  class Misc

    def self.password_generator
      chars = 'abcdefghijklmnopqrstuvwxyz1234567890'
      password = chars.last(10).split(//).sample
      begin
        char = chars[rand(chars.size)]
        password << char if password[-1] != char
      end while password.length < 32
      password
    end

    def self.username_generator
      chars = 'abcdefghijklmnopqrstuvwxyz'
      username = chars.last(10).split(//).sample
      begin
        char = chars[rand(chars.size)]
        username << char if username[-1] != char
      end while username.length < 10
      username
    end
  end
end
