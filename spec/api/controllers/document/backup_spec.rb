require 'spec_helper'
require_relative '../../../../apps/api/controllers/document/backup'

describe Api::Controllers::Document::Backup do
  let(:action) { Api::Controllers::Document::Backup.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
