require 'spec_helper'
require_relative '../../../../apps/api/controllers/users/updateprefences'

describe Api::Controllers::Users::Updateprefences do
  let(:action) { Api::Controllers::Users::Updateprefences.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
