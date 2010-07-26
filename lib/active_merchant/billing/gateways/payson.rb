require 'active_merchant/billing/gateways/payson/payson_response'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PaysonGateway < Gateway
      REDIRECT_URL = 'https://www.payson.se/PaySecure'
      ENDPOINT_URL = 'https://api.payson.se/1.0/Pay/'
      
      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['SE']
      
      # The homepage URL of the gateway
      self.homepage_url = 'https://api.payson.se/'
      
      # The name of the gateway
      self.display_name = 'Payson'
      
      def initialize(options = {})
        requires!(options, :login, :password)
        @options = options
        super
      end  
      
      def authorize(options = {})
        post = {}
        add_receivers(post, options)
        add_customer(post, options)
        add_callbacks(post, options)
        add_meta(post, options)
        
        response = commit('authorize', post)
        @token = response.token if response.success?
        response
      end
      
      def payment_redirection_url
        "#{REDIRECT_URL}?token=#{@token}"
      end

      private                       
      
      def add_receivers(post, options)
        requires!(options, :receivers)
        options[:receivers].each_with_index do |v, i|
          post["receiverList.receiver(#{i}).email"] = v[:email]
          post["receiverList.receiver(#{i}).amount"] = v[:amount]
        end
      end

      def add_customer(post, options)
        requires!(options, :sender)
        post.merge!({'senderEmail' => options[:sender][:email],
            'senderFirstName' => options[:sender][:first_name],
            'senderLastName' => options[:sender][:last_name] })
      end

      def add_callbacks(post, options)
        requires!(options, :return_url, :cancel_url)
        post.merge!({'returnUrl' => options[:return_url],
            'cancelUrl' => options[:cancel_url]})
      end
      
      def add_meta(post, options)
        requires!(options, :memo)
        options[:currency_code] ||= "SEK"
        post.merge!({ 'custom' => options[:custom],
            'memo' => options[:memo],
            'currencyCode' => options[:currency_code]})
      end

      def headers(options)
        { 'PAYSON-SECURITY-USERID' => options[:login],
          'PAYSON-SECURITY-PASSWORD' => options[:password]}
      end

      def parse(body)
        response_slice = body.split('&')
        response_hash = {}

        response_slice.each do |rs|
          rs_split = rs.split('=')
          response_hash[rs_split[0]] = rs_split[1]
        end
        ActiveMerchant::Billing::PaysonResponse.new response_hash
      end

      def endpoint_url(action)
        case action
        when "authorize"
          ENDPOINT_URL
        when "pay"
          REDIRECT_URL
        end
      end
      
      def commit(action, parameters)
        parse( ssl_post(endpoint_url(action), post_data(parameters), headers(@options)) )
      end

      def post_data(parameters)
        parameters.collect { |key, value| "#{key}=#{CGI.escape(value.to_s)}" }.join("&")
      end
    end
  end
end

