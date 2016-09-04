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
# request_permissin&acl=NAME&document=ID&user=USER
#
# acls_of_owner=USER_ID
# aclos_of_document=DOC_ID
#
#
class ACLManager

  include Hanami::Interactor

  expose :commands, :status, :acl_list

  def initialize(command, owner_id)
    @commands = command.split('&').map{|command| command.split('=')} || []
    @queue = @commands.dup
    @owner_id = owner_id
    @status = 'error'
  end

  def create_acl
    verb, permission = @queue.shift
    if verb == 'permission'
      Acl.create(name: @object, permission: permission, owner_id: @owner_id)
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
    document = DocumentRepository.find document_id
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
      puts "*** removing document #{document_id} from acl #{name}"
      acl.remove_document(document_id)
      document.leave_acl name
      @status = 'success'
    else
      @status = 'error'
    end
  end

  def request_permission
    hash = {}
    @queue.each do |key, value|
      hash[key] = value
    end
    acl = AclRepository.find_by_name hash['acl']
    ok = acl.contains_document(hash['document'].to_i) && acl.contains_member(hash['user']) && @object == acl.permission
    if ok
      @status = 'success'
    else
      @status = 'error'
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
    puts "ACL LIST = #{result}"
    @acl_list = result.to_json
    @status = 'success'
  end

  # return list of acls to which the given document belongs
  def acls_of_document
    document_id = @object
    document = DocumentRepository.find document_id
    if document == nil
      @status = 'error'
      return
    end
    @acl_list = document.acls.to_json
    @status = 'success'
  end

  def call

    return if @queue == []

    @verb, @object = @queue.shift

    # return if !(['create_acl', 'remove_acl', 'add_user', 'remove_user', 'add_document', 'remove_document', 'request_permission', 'user_list'].include? @verb)

    send @verb


  end

end
