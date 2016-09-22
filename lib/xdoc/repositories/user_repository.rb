class UserRepository
  include Hanami::Repository

  def self.find_by_username(username)
    query do
      where(username: username)
    end.first
  end

  def self.find_by_identifier(identifier)
    if identifier.class == Fixnum
      UserRepository.find identifier
    else
      UserRepository.find_by_username identifier
    end
  end

end
