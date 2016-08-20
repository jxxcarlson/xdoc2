require 'spec_helper'
require_relative '../../../../apps/api/controllers/images/update'

describe Api::Controllers::Images::Update do
  let(:action) { Api::Controllers::Images::Update.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
