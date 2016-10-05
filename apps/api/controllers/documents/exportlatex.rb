require_relative '../../../../lib/xdoc/interactors/export_latex'


module Api::Controllers::Documents
  class ExportLatex
    include Api::Action


    def call(params)
      ex = LatexExporter.new(params[:id]).call
      puts "ExportLatex: #{params[:id]}"
      self.body = {status: 'success', tar_url: ex.tar_url}.to_json
    end

  end
end
