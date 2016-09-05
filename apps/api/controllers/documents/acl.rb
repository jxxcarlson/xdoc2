require_relative '../../../../lib/xdoc/interactors/acl_manager'


module Api::Controllers::Documents
  class Acl
    include Api::Action

    def call(params)
      puts request.query_string
      result = ACLManager.new(request.query_string, 39).call
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
