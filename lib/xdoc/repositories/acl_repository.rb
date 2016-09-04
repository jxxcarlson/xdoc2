class AclRepository
  include Hanami::Repository

  def self.find_by_name(name)
    query do
      where(name: name)
    end.first
  end

  def self.find_by_owner_id(id)
    query do
      where(owner_id: id)
    end
  end


end
