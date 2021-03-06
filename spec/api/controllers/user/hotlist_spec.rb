require 'spec_helper'
require_relative '../../../../apps/api/controllers/user/hotlist'

describe Api::Controllers::User::Hotlist do
  let(:action) { Api::Controllers::User::Hotlist.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
