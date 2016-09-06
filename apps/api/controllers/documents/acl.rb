require_relative '../../../../lib/xdoc/interactors/acl_manager'


module Api::Controllers::Documents
  class Acl
    include Api::Action

    def call(params)

      token = request.env["HTTP_ACCESSTOKEN"]
      @access = GrantAccess.new(token).call
      @user = UserRepository.find_by_username @access.username

      puts request.query_string
      result = ACLManager.new(request.query_string, @user.id).call
      self.body = { 'acl':request.query_string,
                    'status': result.status,
                    'commands': result.commands,
                    'acl_list': result.acl_list,
                    'permission': result.permission,
                    'permission_granted': result.permission_granted,
                    'permissions': result.permissions

      }.to_json
    end

  end
end
