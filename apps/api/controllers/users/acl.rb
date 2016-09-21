module Api::Controllers::Users
  class Acl
    include Api::Action


    def make_acl_list
      @acl_array = []
      @acls = @user.acls
      @acls.each do |acl_name|
        acl = AclRepository.find_by_name acl_name
        if acl
          @acl_array << {'name' => acl_name, 'documents' => acl.documents}
        end
      end
    end

    def call(params)

      @user = UserRepository.find_by_username params[:username]

      if @user == nil
        reply = {:status => 'success', :error => "User #{params[:username]} not found" }
      else
        make_acl_list
        reply = {:status => 'success', :error => 'none', :acl =>  @acl_array }
      end
      self.body = reply.to_json
    end
  end
end
