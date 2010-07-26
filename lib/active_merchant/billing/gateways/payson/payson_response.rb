module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class PaysonResponse < Response
      SUCCESS = 'SUCCESS'
      FAILURE = 'FAILURE'
      COMPLETED = 'COMPLETED'

      def initialize(params = {})
        @params = params.stringify_keys
      end

      def success?
        status == SUCCESS
      end

      def fail?
        status == FAILURE
      end

      def test?
        false
      end

      def token
        @params['TOKEN']
      end

      def status
        @params['responseEnvelope.ack']
      end

      def params
        @params
      end
      
    end
  end
end