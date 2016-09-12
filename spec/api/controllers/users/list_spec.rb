require 'spec_helper'
require_relative '../../../../apps/api/controllers/users/manage'

describe Api::Controllers::Users::Manage do
  let(:action) { Api::Controllers::Users::Manage.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
