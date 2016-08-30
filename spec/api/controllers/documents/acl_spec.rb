require 'spec_helper'
require_relative '../../../../apps/api/controllers/documents/acl'

describe Api::Controllers::Documents::Acl do
  let(:action) { Api::Controllers::Documents::Acl.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
