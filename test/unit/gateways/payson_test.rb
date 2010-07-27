require 'test_helper'

class PaysonTest < Test::Unit::TestCase
  def setup
    @gateway = PaysonGateway.new(
                 :login => 'login',
                 :password => 'password'
               )

    @credit_card = credit_card
    @amount = 100

    @options = {
      :order_id => '1',
      :billing_address => address,
      :description => 'Store Purchase'
    }
  end

  def test_successful_purchase
    @gateway.expects(:ssl_post).returns(successful_purchase_response)

    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_instance_of
    assert_success response

    # Replace with authorization number from the successful response
    assert_equal '', response.authorization
    assert response.test?
  end

  def test_unsuccessful_request
    @gateway.expects(:ssl_post).returns(failed_purchase_response)

    assert response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert response.test?
  end

  protected

  def successful_authorization
<<-RESPONSE
RESPONSE
  end

  def failed_authorization
<<-RESPONSE
RESPONSE
  end

  def successful_payment_details
<<-HELLO
HELLO
  end

  def failed_payment_details
<<-RESPONSE
errorList.error(0).errorId  ::  520003
errorList.error(0).message  ::  Authentication failed; Credentials were not valid
responseEnvelope.ack  ::  FAILURE
responseEnvelope.timestamp  ::  2010-07-27T15:05:22
responseEnvelope.version  ::  1.0
RESPONSE
  end

end
