require 'spec_helper'
require_relative '../../../../apps/api/controllers/documents/exportlatex'

describe Api::Controllers::Documents::ExportLatex do
  let(:action) { Api::Controllers::Documents::ExportLatex.new }
  let(:params) { Hash[] }

  it 'is successful' do
    response = action.call(params)
    response[0].must_equal 200
  end
end
