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

  def add_document(doc)
    documents = self.documents || []
    documents << doc
    self.documents = documents
    AclRepository.update self
  end

  def index_of_document(doc)
    self.documents.index(doc)
  end

  def contains_document(doc)
    self.documents.index(doc) != nil
  end

  def remove_document(doc)
    doc = doc.to_i
    k = self.index_of_document(doc)
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


end
