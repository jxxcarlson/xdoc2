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
        # puts "DEBUG:   -- token NOT present"
      end
    end

    def report(reply_hash)
      doc = reply_hash[:document]
      if @user
        puts "API read: #{doc[:title]}, user: #{@user.username}"
      else
        puts "API read: #{doc[:title]}, user: anonymoous"
      end
    end

    def call(params)
      check_user_and_access
      if @access_granted
        result = ReadDocument.new(params['id'], @user).call
        HotListManager.new(@user, 'push', result.document).call.hotlist
      else
        result = ReadDocument.new(params['id'], nil).call
      end
      reply_hash = result.reply.to_h
      report(reply_hash)
      self.body = reply_hash.to_json
    end

    def verify_csrf_token?
      false
    end

  end
end
