require 'spec_helper'
require_relative '../../../../apps/api/controllers/users/getprefences'

describe Api::Controllers::Users::Getprefences do
  let(:action) { Api::Controllers::Users::Getprefences.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
