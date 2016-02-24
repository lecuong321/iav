module Yodlee
  class Config

    class_attribute :coblogin,
                    :login,

                    :getFastLinkToken,
                    :getAccounts

    # Load yaml settings
    YAML.load_file("#{Rails.root}/config/yodlee.yml").each do |key, value|
      self.send("#{key}=", value)
    end

  end
end
