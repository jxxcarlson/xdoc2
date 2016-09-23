require 'hanami/interactor'


# Process API requests to create or modify acls
# and to interrogate acls for permission
#
# API:
#
# create_acl=NAME&permission=EDIT|READ
# remove_acl=NAME
#
# add_user=USER&acl=NAME
# remove_user=USER&acl=NAME
#
# add_document=ID&acl=NAME
# remove_document=ID&acl=NAME
#
# get_permission=ACL_NAME&document=doc_ID&user=USER
# get_permissions=doc_ID&user=USER
# grant_permission=docID&user=USER&permission=PERMISSION
#
# acls_of_owner=USER_ID
# acls_of_document=DOC_ID
#
#
class ACLManager

  include Hanami::Interactor

  expose :commands, :status, :acl_list, :permission, :permissions, :permission_granted

  def initialize(command, owner_id)
    @commands = command.split('&').map{|command| command.split('=')} || []
    @queue = @commands.dup
    @owner_id = owner_id
    @owner = UserRepository.find @owner_id
    @permission_granted = false
    @status = 'error'
  end

  def create_acl
    verb, permission = @queue.shift
    acl_name = "#{@owner.username}.#{@object}"
    if verb == 'permission'
      Acl.create(name: acl_name, permission: permission, owner_id: @owner_id)
      @status = 'success'
    else
      @status = 'error'
    end
  end

  def remove_acl
    @status = Acl.remove(@object)
  end

  def add_user
    username = @object
    user = UserRepository.find_by_username username
    if user == nil
      @status = 'error'
      return
    end
    verb, name = @queue.shift
    if verb == 'acl'
      acl = AclRepository.find_by_name name
      acl.add_member(username)
      user.join_acl name
      @status = 'success'
    else
      @status = 'error'
    end
  end

  def remove_user
    username = @object
    user = UserRepository.find_by_username username
    if user == nil
      @status = 'error'
      return
    end
    verb, name = @queue.shift
    if verb == 'acl'
      acl = AclRepository.find_by_name name
      acl.remove_member(username)
      user.leave_acl name
      @status = 'success'
    else
      @status = 'error'
    end
  end

  def add_document
    document_id = @object
    document = DocumentRepository.find_by_id_or_identifier document_id
    if document == nil
      @status = 'error'
      return
    end
    verb, name = @queue.shift
    if verb == 'acl'
      acl = AclRepository.find_by_name name
      acl.add_document(document_id)
      document.join_acl name
      @status = 'success'
    else
      @status = 'error'
    end
  end

  def remove_document
    document_id = @object
    document = DocumentRepository.find document_id
    if document == nil
      @status = 'error'
      return
    end
    verb, name = @queue.shift
    if verb == 'acl'
      acl = AclRepository.find_by_name name
      acl.remove_document(document_id)
      document.leave_acl name
      @status = 'success'
    else
      @status = 'error'
    end
  end

  def get_permission
    acl_name = @object
    _document, document_id = @queue.shift
    _user, user_id = @queue.shift
    acl = AclRepository.find_by_name acl_name
    if acl == nil
      return
    end
    if acl.contains_document(document_id.to_i) && acl.contains_member(user_id)
      @permission = acl.permission
      @status = 'success'
    else
      @status = 'error'
    end
  end

  def grant_permission
    document_id = @object
    document = DocumentRepository.find_by_id_or_identifier document_id
    return if document == nil
    _user, user_id = @queue.shift
    _permission, permission = @queue.shift
    document.acls.each do |acl_name|
      acl = AclRepository.find_by_name acl_name
      if acl.contains_document(document_id.to_i) && acl.contains_member(user_id) && acl.permission == permission
        @permission_granted = true
        @status = 'success'
        break
      end
    end

  end

  def get_permissions
    document_id = @object
    document = DocumentRepository.find_by_id_or_identifier document_id
    return if document == nil

    _user, user_identifier = @queue.shift

    # ensure that the user_id is the username
    if user_identifier.class == String
      user = UserRepository.find_by_username user_identifier
    else
      user = UserRepository.find user_identifier
    end

    document_id = document_id.to_i
    @permissions = []

    if document.public
      @permissions << 'read'
    end

    if document.owner_id == user.id
      @permissions << 'edit'
      @permissions << 'read' if !(@permissions.include? 'read')
    end

    if @permissions.count == 2
      @status = 'success'
      return
    end

    document.acls.each do |acl_name|
      acl = AclRepository.find_by_name acl_name
      if acl.contains_document(document_id) && acl.contains_member(user.username)
        @permissions << acl.permission if !(@permissions.include? acl.permission)
        break if @permissions.count == 2
      end
      @status = 'success'
    end

  end

  # return list of acls owned by given user
  def acls_of_owner
    # normalize and handle error
    if @object =~ /\A\d*\z/
      owner_id = @object
      owner = UserRepository.find @object
      if owner == nil
        @status = 'error'
        return
      end
    else
      owner = UserRepository.find_by_username @object
      if owner == nil
        @status = 'error'
        return
      end
      owner_id = owner.id
    end

    # get acl list
    result = []
    AclRepository.find_by_owner_id(owner_id).all.each do |acl|
      result <<  acl.to_h
    end
    @acl_list = result.to_json
    @status = 'success'
  end

  # return list of acls to which the given document belongs
  def acls_of_document
    document_id = @object
    document = DocumentRepository.find_by_id_or_identifier document_id
    if document == nil
      @status = 'error'
      return
    end
    @acl_list = document.acls.to_json
    @status = 'success'
  end

  def call

    return if @owner == nil

    return if @queue == []

    @verb, @object = @queue.shift

    # return if !(['create_acl', 'remove_acl', 'add_user', 'remove_user', 'add_document', 'remove_document', 'request_permission', 'user_list'].include? @verb)

    send @verb


  end

end
