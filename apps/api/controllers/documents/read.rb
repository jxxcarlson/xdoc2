require_relative '../../../../lib/xdoc/interactors/grant_access'
require_relative '../../../../lib/xdoc/modules/verify'

include Permission

module Api::Controllers::Documents
  class Read
    include Api::Action

    def return_document(document)

      if document
        if @user
          command = "get_permissions=#{document.id}&user=#{@user.username}"
          permissions = ACLManager.new(command, @user.id).call.permissions
        elsif document.public
          permissions = ['read']
        else
          permissions = []
        end

        dict = document.dict || {}
        can_show_source = dict['can_show_source'] || 'no'

        checked_out_to = CheckoutManager.new("status=#{document.id}").call.reply

        def process_permissions(permissions, document)
          can_edit = permissions.include? 'edit'
          puts "USER #{@user.username}, can_edit = #{can_edit}"
          if can_edit
            document_hash = document.hash
          else
            document_hash = document.public_hash
          end
          document_hash
        end

        if @user
          command = "get_permissions=#{params['id']}&user=#{@access.username}"
          permissions = ACLManager.new(command, @user.id).call.permissions
          if permissions
            document_hash = process_permissions(permissions, document)
          else
            document_hash = document.public_hash
          end
        end

        hash = {'status': 'success',
                'document': document_hash,
                'permissions': permissions,
                'checked_out_to': checked_out_to,
                'can_show_source': can_show_source
        }
        self.body = hash.to_json
      else
        self.body = { 'status' => 'success', 'error' => 'Error: document not found or processed' }.to_json
      end
    end

    def  get_document(id)
      puts "DEBUG: API read, get_document, username = #{@access.username}" if @access
      puts "DEBUG: API read, get_document, id = #{id}"
      if id =~ /\A[1-9][0-9]*\z/
        document = DocumentRepository.find(id)
      else
        document = DocumentRepository.find_by_identifier(id)
      end



      if document
        if @access
          puts "API: read, #{@access.username}, #{id}, #{document.title}"
        else
          puts "API: read, anonymous, #{id}, #{document.title}"
        end
        if document.has_subdocuments
          document.update_document_links
        end
      end
      document
    end

    def check_user_and_access
      token = request.env["HTTP_ACCESSTOKEN"]
      if token
        @access = GrantAccess.new(token).call
        @user = UserRepository.find_by_username @access.username
        access_granted = @access.valid
      else
        puts "DEBUG:   -- token NOT present"
      end
    end

    def call(params)
      access_granted = false
      check_user_and_access
      document = get_document(params['id'])

      if document == nil
        document = DocumentRepository.find ENV['DEFAULT_DOCUMENT_ID']
      end

      if access_granted && document != nil
        hotlist = HotListManager.new(@user, 'push', document).call.hotlist
        puts "HOTLIST: #{hotlist}"
        return_document(document)
      elsif document.public
        return_document(document)
      else
        self.body = {'status' => 'success', 'error' => 'access not granted'}.to_json
      end

    end


    def verify_csrf_token?
      false
    end

  end
end
