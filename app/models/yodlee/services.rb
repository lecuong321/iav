module Yodlee
  class Services
    include HTTParty

    def query opts
      method   = opts[:method].to_s.downcase
      endpoint = URI.parse(URI.encode(opts[:endpoint]))
      response = self.class.send(method, endpoint.to_s, query: opts[:params], headers: opts[:headers])
      data     = response.parsed_response

      if response.success?
        if [ TrueClass, FalseClass, Fixnum ].include?(data.class)
          data
        else
          convert_to_mash(data)
        end
      else
        data
      end
    end

    def get opts
      options = {}
      options.merge!({headers: opts[:headers]})
      method   = opts[:method].to_s.downcase
      endpoint = URI.parse(URI.encode(opts[:endpoint]))
      response = self.class.get(endpoint.to_s, options)
      data     = response.parsed_response

      if response.success?
        if [ TrueClass, FalseClass, Fixnum ].include?(data.class)
          data
        else
          convert_to_mash(data)
        end
      else
        data
      end
    end

    def convert_to_mash data
      if data.is_a? Hash
        Hashie::Mash.new(data)
      elsif data.is_a? Array
        data.map { |d| Hashie::Mash.new(d) }
      end
    end

  end
end
