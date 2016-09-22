require_relative '../../../../lib/xdoc/interactors/grant_access'
require_relative '../../../../lib/xdoc/interactors/read_document'
require_relative '../../../../lib/xdoc/modules/verify'

include Permission

module Api::Controllers::Documents
  class Read
    include Api::Action


    def check_user_and_access
      token = request.env["HTTP_ACCESSTOKEN"]
      if token
        @access = GrantAccess.new(token).call
        @user = UserRepository.find_by_username @access.username
        @access_granted = @access.valid
      else
        puts "DEBUG:   -- token NOT present"
      end
    end

    def call(params)
      check_user_and_access
      if @access_granted
        result = ReadDocument.new(params['id'], @user).call.result
        HotListManager.new(@user, 'push', result.document).call.hotlist
      else
        result = ReadDocument.new(params['id'], nil).call.result
      end
      self.body = {'status' => 'success', 'error' => 'access not granted'}.to_json
    end


    def verify_csrf_token?
      false
    end

  end
end
