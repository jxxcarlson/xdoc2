require 'bcrypt'

class User
  include Hanami::Entity

  attributes :username, :admin, :status,
             :email, :password_hash,
             :created_at, :updated_at,
             :dict, :links

  def initialize(hash)
    super
    self.dict  ||= {}
    self.links ||= {}
    self.admin ||= false
  end

  def change_password(new_password)
    self.password_hash = BCrypt::Password.create(new_password)
    # UserRepository.update self
  end

  def verify_password(password)
    return BCrypt::Password.new(self.password_hash) == password
  end


  def get_preference(key)
    dict ||= self.dict || {}
    preference_dict = dict['preferences'] || {}
    preference_dict[key]
  end

  def admissible_preferences
    ['doc_format']
  end

  def admissible_values
    {'doc_format' => ['text', 'asciidoc', 'asciidoc-ms','asciidoc-latex']}
  end

  def set_preference(key, value)
    return if admissible_preferences.include? key == false
    return if !(admissible_values[key].include? value)
    dict || self.dict || {}
    preference_dict = dict['preferences'] || {}
    preference_dict[key] = value
    self.dict['preferences'] = preference_dict
    UserRepository.update self
  end


end
