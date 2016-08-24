class Acl
  include Hanami::Entity

  attributes :id, :name, :owner_id, :permission, :members, :created_at, :updated_at

  def self.create(params)
    name = params[:name]
    owner_id = params[:owner_id]
    permission = params[:permission]
    acl = Acl.new(name: name, owner_id: owner_id, permission: permission)
    acl.members = params[:members] || []
    acl.created_at = DateTime.now
    acl.updated_at = acl.created_at
    acl = AclRepository.create acl
    acl
  end

  def add(member)
    members = self.members || []
    members << member
    self.members = members
    AclRepository.update self
  end

  def index_of(member)
    self.members.index(member)
  end

  def contains(member)
    self.members.index(member) != nil
  end

  def remove(member)
    k = self.index_of(member)
    members = self.members
    members.delete_at k
    self.members = members
    AclRepository.update self
  end

  def grants(user, permission)
    permission == self.permission &&  self.contains(user)
  end

  def self.grants(user, permission, acl_list)
    result = false
    acl_list.each do |acl|
      result = acl.grants(user, permission)
      break if result == true
    end
    result
  end


end
