class AclRepository
  include Hanami::Repository

  def self.find_by_name(name)
    query do
      where(name: name)
    end.first
  end
end
