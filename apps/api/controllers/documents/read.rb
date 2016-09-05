require_relative '../../../../lib/xdoc/interactors/grant_access'
require_relative '../../../../lib/xdoc/modules/verify'

include Permission

module Api::Controllers::Documents
  class Read
    include Api::Action

    def return_document(document)
      if document
        command = "get_permissions=#{document.id}&user=#{@user.username}"
        permissions = ACLManager.new(command, @user.id).call.permissions
        checked_out_to = CheckoutManager.new("status=#{document.id}").call.reply
        hash = {'status' => 'success', 'document' => document.hash, 'permissions': permissions, 'checked_out_to': checked_out_to }
        self.body = hash.to_json
      else
        self.body = { "error" => "500 Server error: document not found or processed" }.to_json
      end
    end

    def  get_document(id)
      if id =~ /\A[1-9][0-9]*\z/
        document = DocumentRepository.find(id)
      else
        document = DocumentRepository.find_by_identifier(id)
      end
      if @access
        puts "API: read, #{@access.username}, #{id}, #{document.title}"
      else
        puts "API: read, anonymous, #{id}, #{document.title}"
      end

      if document
        if document.has_subdocuments
          document.update_document_links
        end
      end
      document
    end

    def call(params)

      token = request.env["HTTP_ACCESSTOKEN"]
      @access = GrantAccess.new(token).call
      @user = UserRepository.find_by_username @access.username

      document = get_document(params['id'])

      if document == nil
        puts "Can't find document for id = #{params['id']}"
      end

      if @access.valid
        return_document(document)
      elsif document.public
        return_document(document)
      else
        self.body = error_document_response
      end

    end


    def verify_csrf_token?
      false
    end

  end
end
