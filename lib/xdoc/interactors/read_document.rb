require 'hanami/interactor'


class ReadDocument

  include Hanami::Interactor

  expose :document, :document_hash, :reply

  def initialize(document_id, user = nil)
   @document_id = document_id
   @user = user
  end


  def get_document
    if @document_id =~ /\A[1-9][0-9]*\z/
      @document = DocumentRepository.find(@document_id)
    else
      @document = DocumentRepository.find_by_identifier(@document_id)
    end
  end

  def update_subdocuments
    if @document.has_subdocuments
      @document.update_document_links
    end
  end

  def handle_nil_document
    if @document == nil
      @document = DocumentRepository.find ENV['DEFAULT_DOCUMENT_ID']
      return
    end
  end


  def  get_permissions
    if @user
      command = "get_permissions=#{@document_id}&user=#{@user.username}"
      @permissions = ACLManager.new(command, @user.id).call.permissions
    elsif @document.public
      @permissions = ['read']
    else
      @permissions = []
    end
  end

  def process_permissions
    if @permissions
      can_edit = @permissions.include? 'edit'
    else
      can_edit = false
    end

    if can_edit
      @document_hash = @document.hash
    else
      @document_hash = @document.public_hash
    end
  end

  def can_show_source
    dict = @document.dict || {}
    dict['can_show_source'] || 'no'
  end

  def checked_out_to
    CheckoutManager.new("status=#{@document.id}").call.reply
  end

  def prepare_document

      get_permissions
      process_permissions

      @reply = {'status': 'success',
              'document': @document_hash,
              'permissions': @permissions,
              'checked_out_to': checked_out_to,
              'can_show_source': can_show_source
      }
  end


  ## self.body = {'status' => 'success', 'error' => 'access not granted'}.to_json

  def call
    get_document
    handle_nil_document
    update_subdocuments
    prepare_document
  end

end




