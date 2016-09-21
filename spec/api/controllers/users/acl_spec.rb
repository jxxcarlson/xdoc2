require 'spec_helper'
require_relative '../../../../apps/api/controllers/users/acl'

describe Api::Controllers::Users::Acl do
  let(:action) { Api::Controllers::Users::Acl.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
