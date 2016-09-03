require 'spec_helper'
require_relative '../../../../apps/api/controllers/documents/checkout'

describe Api::Controllers::Documents::Checkout do
  let(:action) { Api::Controllers::Documents::Checkout.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
