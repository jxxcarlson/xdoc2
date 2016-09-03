require 'spec_helper'
require_relative '../../../../apps/api/controllers/document/checkout'

describe Api::Controllers::Document::Checkout do
  let(:action) { Api::Controllers::Document::Checkout.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
