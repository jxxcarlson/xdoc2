
require_relative '../../../../lib/xdoc/interactors/find_documents'
require_relative '../../../../lib/xdoc/interactors/grant_access'
require_relative '../../../../lib/xdoc/modules/verify'

include Permission

module Api::Controllers::Documents
  class Find
    include Api::Action

    def search


    end

    def call(_params)
      puts "API: find"

      ## Get access token from request headers and compute @access
      token = request.env["HTTP_ACCESSTOKEN"]
      @access = GrantAccess.new(token).call

      if request.query_string =~ /deleted=/
        search_result = DeletedDocuments.new(request.query_string, @access).call
        result  = { :status => 'success',
                    :document_count => search_result.document_hash_array.count,
                    :documents => search_result.document_hash_array,
        }.to_json
      else
        search_result = FindDocuments.new(request.query_string, @access).call
        result  = { :status => 'success',
                    :document_count => search_result.document_count,
                    :documents => search_result.document_hash_array,
                    :first_document => search_result.first_document.hash
        }.to_json
      end


      # result2 = JSON.parse(result)
      # puts "\n\nfirst_document::: #{result2['first_document']['title']}\n\n"

      self.body = result
    end


    def verify_csrf_token?
      false
    end

  end
end
