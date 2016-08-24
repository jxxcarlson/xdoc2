require_relative '../../../../lib/xdoc/interactors/grant_access'
require_relative '../../../../lib/xdoc/modules/verify'
require_relative '../../../../lib/xdoc/interactors/create_document'

include Permission

module Api::Controllers::Documents
  class Create
    include Api::Action



    def create_document
      result = CreateDocument.new(params, @access.user_id).call
      if result.status == 'success'
        hash = result.new_document.to_hash
        puts "\n\nNEW DOCUMENT: #{hash}\n\n"
        @reply  = {'status' => 'success', 'document' => hash }
        puts "Created document with hash = #{hash}"
      else
        @reply = '{ "error" => "500 Server error: document not created" }'
      end
    end

    def call(params)

      query_string =  request.query_string || ""

      puts "API: new document"
      puts "options: #{params['options']}"
      puts "current_document_id: #{params['current_document_id']}"
      puts "parent_document_id: #{params['parent_document_id']}"
      puts "request.query_string: #{query_string}"


      verify(params)


      if @access.valid
        create_document
      else
        @reply = {'status': 'error'}
      end

      puts "@reply = #{@repy}"
      self.body = @reply.to_json

    end

    def verify_csrf_token?
      false
    end

  end
end

