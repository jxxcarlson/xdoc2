
require_relative '../../../../lib/xdoc/modules/verify'

module Api::Controllers::Documents
  class Delete
    include Api::Action

    include Permission

    def reply(mode, id)
      case mode
        when 'soft'
          { 'status': 'success','info': "document #{id} deleted (soft)" }
        when 'hard'
          { 'status': 'success','info': "document #{id} deleted (hard)" }
        when 'undelete'
          { 'status': 'success','info': "document #{id} undeleted" }
      end
    end

    def delete_document(params)
      id = params['id']
      document = DocumentRepository.find(id)
      command = request.query_string
      _verb, mode = command.split('=')

      if document && document.owner_id == @access.user_id
        case mode
          when 'soft'
            puts "Soft delete document #{id}"
            document.set_status('deleted')
            document.unlink
          when 'hard'
            puts "Hard delete document #{id}"
            NSDocument.delete document
          when 'undelete'
            puts "Undeleting document #{id}"
            document.set_status('')
        end
        reply =  reply(mode, id)
      else
        self.body = { "error" => "500 Server error: document not found or processed or permissions invalid" }.to_json
      end
      self.body = reply.to_json
    end

    def call(params)

      verify_request(request)
      puts "@access.valid: #{@access.valid}"
      puts "@access.username: #{@access.username}"

      document = DocumentRepository.find params['id']

      author = UserRepository.find_by_username @access.username

      puts "author.id: #{author.id}"
      puts "document.owner_id: #{document.owner_id}"



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
