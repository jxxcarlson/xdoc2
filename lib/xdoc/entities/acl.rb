class Acl
  include Hanami::Entity

  attributes :id, :name, :owner_id, :permission, :members, :documents, :created_at, :updated_at

  def self.create(params)
    name = params[:name]
    owner_id = params[:owner_id]
    permission = params[:permission]
    acl = Acl.new(name: name, owner_id: owner_id, permission: permission, members: [], documents: [])
    acl.members = params[:members] || []
    acl.created_at = DateTime.now
    acl.updated_at = acl.created_at
    acl = AclRepository.create acl
    acl
  end

  def json
    self.to_h.to_json
  end

  def self.remove(name)
    acl = AclRepository.find_by_name(name)
    if acl
      AclRepository.delete(acl)
      "success"
    else
      "error"
    end
  end

  def add_member(member)
    members = self.members || []
    members << member
    self.members = members
    AclRepository.update self
  end

  def index_of_member(member)
    self.members.index(member)
  end

  def contains_member(member)
    self.members.index(member) != nil
  end

  def remove_member(member)
    k = self.index_of_member(member)
    members = self.members
    members.delete_at k
    self.members = members
    AclRepository.update self
  end

  ##
  ## Documents
  ##

  def add_document(doc_id)
    documents = self.documents || []
    doc = DocumentRepository.find doc_id
    if doc && !(self.contains_document(doc_id))
      documents << [doc_id, doc.title]
      self.documents = documents
      AclRepository.update self
    end

  end

  def index_of_document(doc_id)
    self.documents.map{ |pair| pair[0].to_i }.index(doc_id)
  end

  def contains_document(doc_id)
    self.index_of_document(doc_id) != nil
  end

  def remove_document(doc_id)
    doc_id = doc_id.to_i
    k = self.index_of_document(doc_id)
    puts "*** acl, remove document, k = #{k}"
    if k
      documents = self.documents
      documents.delete_at k
      self.documents = documents
      AclRepository.update self
    end
  end

  ########

  def grants(user, doc_id, permission)
    permission == self.permission &&  self.contains_member(user) &&  self.contains_document(doc_id)
  end

  def self.grants(user, doc_id, permission, acl_list)
    result = false
    acl_list.each do |acl|
      result = acl.grants(user, doc_id, permission)
      break if result == true
    end
    result
  end

  def self.grant_permission(user, document, permission)

    document = document.id if document.class == String
    document = DocumntRepository.find document if document.class == Fixnum
    user = user.id  if user.class == String
    user = UserRepository.find user if user.class == Fixnum

    return true if document.owner_id == user.id
    return true if permission == 'read' and document.public

    access_list = document.access_list
    Acl.grants(user, document.id, permission, access_list)

  end


end
