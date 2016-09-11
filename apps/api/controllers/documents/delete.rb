
require_relative '../../../../lib/xdoc/modules/verify'

module Api::Controllers::Documents
  class Delete
    include Api::Action

    include Permission

    def delete_document(params)
      id = params['id']
      document = DocumentRepository.find(id)
      command = request.query_string

      if document && document.owner_id == @access.user_id
        case command
          when 'soft'
            document.set_status('deleted')
          when 'hard'
            NSDocument.delete document
          when 'undelete'
            document.set_status('')
          else
            document.set_status('deleted')
        end
        puts "Document #{id} deleted"
        reply =  { 'status': 'success','info': "document{#id} deleted" }
      else
        self.body = { "error" => "500 Server error: document not found or processed or permissions invalid" }.to_json
      end
      self.body = reply.to_json
    end

    def call(params)

      verify_request(request)

      document = DocumentRepository.find params['id']
      author = UserRepository.find_by_username @access.username

      if @access.valid  && author.id == document.owner_id
        delete_document(params)
      else
        self.body = error_document_response('Sorry, you do not have access to that document')
      end

    end

    def verify_csrf_token?
      false
    end


  end
end
