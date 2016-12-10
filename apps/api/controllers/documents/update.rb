require_relative '../../../../lib/xdoc/interactors/render_asciidoc'
require_relative '../../../../lib/xdoc/modules/verify'
require_relative '../../../../lib/xdoc/interactors/update_document'

module Api::Controllers::Documents
  class Update
    include Api::Action
    include Permission


    def call(params)

      verify_request(request)
      user = UserRepository.find_by_username @access.username
      command = "get_permissions=#{params['id']}&user=#{@access.username}"
      permissions = ACLManager.new(command, user.id).call.permissions
      can_edit = permissions.include? 'edit'

      if @access.valid && can_edit
        puts "DEBUG update doc: access granted to user #{@access.username}"
        puts "DEBUG update doc: request.query_string #{request.query_string}"''
        ## puts "QQQ: update, token = #{@access}"
        ## puts "REQUEST FOR UPDATE: #{params['text']}"
        result = UpdateDocument.new(params, request.query_string, {username: @access.username}).call
        if result.status == 'success'
          self.body = result.hash
          ## puts("RESULT OF UPDATE: #{self.body}")
        else
          self.body = error_document_response('Sorry, unable to update document')
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
