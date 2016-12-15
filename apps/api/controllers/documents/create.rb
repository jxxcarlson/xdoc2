require_relative '../../../../lib/xdoc/interactors/grant_access'
require_relative '../../../../lib/xdoc/modules/verify'
require_relative '../../../../lib/xdoc/interactors/create_document'

include Permission

module Api::Controllers::Documents
  class Create
    include Api::Action

    def parameters
      # params.env['router.params']
      puts "CREATE DOCUMENT ROUTER PARAMS: #{params.env['router.params']}"
      # Example: options = {"child"=>false, "position"=>"null"}
      # options = {"child"=>true|false, "position"=>null|above|below}
      # position = null if child = false // actually, position is ignored in this case
      output_hash = {}
      output_hash['title'] = params['title'] || 'Untitled Document'
      output_hash['options'] = params['options']
      output_hash['current_document_id'] = params['current_document_id']
      output_hash['parent_document_id'] = params['parent_document_id']
      puts "output_hash: #{output_hash}"
      output_hash
    end

    def create_document
      result = CreateDocument.new(parameters, @access.user_id).call
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
      puts "REPLY TO CREATE DOCUMENT: #{@reply}"
      self.body = @reply.to_json

    end

    def verify_csrf_token?
      false
    end

  end
end

