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
# request_permissin&acl=NAME&dcument=ID&user=USER
#
#
class ACLManager

  include Hanami::Interactor

  expose :commands, :status

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
    verb, name = @queue.shift
    if verb == 'acl'
      acl = AclRepository.find_by_name name
      acl.add_member(@object)
      @status = 'success'
    else
      @status = 'error'
    end
  end

  def remove_user
    verb, name = @queue.shift
    if verb == 'acl'
      acl = AclRepository.find_by_name name
      acl.remove_member(@object)
      @status = 'success'
    else
      @status = 'error'
    end
  end

  def add_document
    verb, name = @queue.shift
    if verb == 'acl'
      acl = AclRepository.find_by_name name
      acl.add_document(@object)
      @status = 'success'
    else
      @status = 'error'
    end
  end

  def remove_document
    verb, name = @queue.shift
    if verb == 'acl'
      acl = AclRepository.find_by_name name
      acl.remove_document(@object)
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

  def call

    return if @queue == []

    @verb, @object = @queue.shift

    return if !(['create_acl', 'remove_acl', 'add_user', 'remove_user', 'add_document', 'remove_document', 'request_permission'].include? @verb)

    send @verb


  end

end
