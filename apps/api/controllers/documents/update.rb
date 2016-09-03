require_relative '../../../../lib/xdoc/interactors/render_asciidoc'
require_relative '../../../../lib/xdoc/modules/verify'
require_relative '../../../../lib/xdoc/interactors/update_document'

module Api::Controllers::Documents
  class Update
    include Api::Action
    include Permission


    def call(params)
      puts "API: update #{params['id']}"
      puts "  -- kind: #{params['kind']}"

      verify_request(request)

      if @access.valid && @access.username == params['author_name']
        result = UpdateDocument.new(params, request.query_string, {username: @access.username}).call
        if result.status == 'success'
          self.body = result.hash
        else
          self.body = error_document_response('Sorry, something went wrong')
        end
      else
        self.body = error_document_response('Sorry, you do not have access to that document')
      end

    end


    def verify_csrf_token?
      false
    end

  end
end
