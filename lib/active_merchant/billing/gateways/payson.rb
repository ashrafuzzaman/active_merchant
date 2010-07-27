require 'active_merchant/billing/gateways/payson/payson_response'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PaysonGateway < Gateway
      ENDPOINT_URLS = {
        :production => {
          :authorize => 'https://api.payson.se/1.0/Pay/',
          :pay => 'https://www.payson.se/PaySecure/',
          :validate => 'https://api.payson.se/1.0/Validate/',
          :payment_details => 'https://api.payson.se/1.0/PaymentDetails/'
        }
      }

      # The name of the gateway
      self.display_name = 'Payson'
      # The homepage URL of the gateway
      self.homepage_url = 'https://api.payson.se/'
      # The countries the gateway supports merchants from as 2 digit ISO country codes
      self.supported_countries = ['SE']
      # The default currency for the transactions if no currency is provided
      self.default_currency = 'SEK'
      # The format of the amounts used by the gateway
      # :dollars => '12.50'
      # :cents => '1250'
      self.money_format = :dollars

      def initialize(options = {})
        requires!(options, :login, :password)
        @options = options
        super
      end

      def authorize(options = {})
        @post = ActiveMerchant::PostData.new

        self.add_receivers(options)
        self.add_customer(options)
        self.add_callbacks(options)
        self.add_meta(options)

        response = commit('authorize')
        @token = response.success? ? response.token : nil
        response
      end

      def payment_redirection_url(token = nil)
        endpoint = endpoint_url('pay')
        token = token || @token
        "#{endpoint}?token=#{token}"
      end

      def payment_details(token = nil)
        endpoint = endpoint_url(:payment_details)
        token = token || @token
        url = "#{endpoint}?token=#{token}"

        response_body = ssl_request(:get, url, nil)
        ActiveMerchant::Billing::PaysonResponse.new(self.parse(response_body))
      end

      protected

        def add_receivers(options)
          requires!(options, :receivers)
          options[:receivers].each_with_index do |v, i|
            @post["receiverList.receiver(#{i}).email"] = v[:email]
            @post["receiverList.receiver(#{i}).amount"] = v[:amount]
          end
        end

        def add_customer(options)
          requires!(options, :sender)
          @post.merge!('senderEmail' => options[:sender][:email],
                      'senderFirstName' => options[:sender][:first_name],
                      'senderLastName' => options[:sender][:last_name])
        end

        def add_callbacks(options)
          requires!(options, :return_url, :cancel_url)
          @post.merge!('returnUrl' => options[:return_url],
                      'cancelUrl' => options[:cancel_url])
        end

        def add_meta(options)
          requires!(options, :memo)
          options[:currency_code] ||= self.default_currency
          @post.merge!('custom' => options[:custom],
                      'memo' => options[:memo],
                      'currencyCode' => options[:currency_code])
        end

        def headers(options)
          {'PAYSON-SECURITY-USERID' => options[:login],
           'PAYSON-SECURITY-PASSWORD' => options[:password]}
        end

        def parse(body)
          return {} if body.blank?

          body.split('&').inject({}) do |memo, chunk|
            next if chunk.empty?
            key, value = chunk.split('=', 2)
            next if key.empty?
            value = value.nil? ? nil : CGI.unescape(value)
            memo[CGI.unescape(key)] = value
            memo
          end
        end

        def endpoint_url(action)
          ENDPOINT_URLS[self.gateway_mode][action.to_sym]
        rescue
          ENDPOINT_URLS[:production][action.to_sym]
        end

        def commit(action, post = ActiveMerchant::PostData.new)
          @post.merge!(post)
          response_body = ssl_post(endpoint_url(action), @post.to_post_data, headers(@options))
          ActiveMerchant::Billing::PaysonResponse.new(self.parse(response_body))
        end
    end
  end
end
