require 'spec_helper'
require_relative '../../../../apps/api/controllers/documents/print'

describe Api::Controllers::Documents::Print do
  let(:action) { Api::Controllers::Documents::Print.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
