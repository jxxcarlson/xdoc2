module Api::Controllers::Documents
  class Acl
    include Api::Action

    def call(params)
      self.body = params[:acl_commmand]
    end
    
  end
end
