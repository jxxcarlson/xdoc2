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

  def hash
    return {'id' => self.id,
            'name' => self.username,
            'email' => self.email
            }
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
    ['doc_format', 'tex_macro_file']
  end

  def admissible_values
    {'doc_format' => ['text', 'asciidoc', 'asciidoc-ms','asciidoc-latex']}
  end

  def set_preference(key, value)
    return if admissible_preferences.include? key == false
    # return if !(admissible_values[key].include? value)
    dict || self.dict || {}
    preference_dict = dict['preferences'] || {}
    preference_dict[key] = value
    self.dict['preferences'] = preference_dict
    UserRepository.update self
  end

  def join_acl(name)
    acl = AclRepository.find_by_name(name)
    return if acl == nil
    return if !(acl.contains_member(self.username))
    dict = self.dict || {}
    my_acls = dict['acl'] || []
    if !(my_acls.include? name)
      my_acls << name
      self.dict  ||= {}
      self.dict['acl'] = my_acls
      UserRepository.update self
    end
  end

  def leave_acl(name)
    acl = AclRepository.find_by_name(name)
    return if acl == nil
    # return if !(acl.contains_member(self.username))
    dict = self.dict || {}
    my_acls = dict['acl'] || []
    if my_acls.include? name
      my_acls.delete name
      self.dict  ||= {}
      self.dict['acl'] = my_acls
      UserRepository.update self
    end
  end

  def acls
    dict = self.dict || {}
    dict['acl'] || []
  end

  def has_acl(name)
    self.acls.include? name
  end

  # temporary

  def self.make_home_pages
    text = "Skeleton home page. Edit it to make like you want it to be.\n\n"
    text << "xref::227[Manuscripta User Manual]\n\n"
    text << "xref::152[Asciidoc Guide]\n\n"
    UserRepository.all.each do |user|
      CreateHomePage.new(user, text).call
    end
  end

  def self.edit_home_pages
    text = "Skeleton home page. Edit it to make like you want it to be.\n\n"
    text << "xref::227[Manuscripta User Manual]\n\n"
    text << "xref::152[Asciidoc Guide]\n\n"
    rendered_text = ::RenderAsciidoc.new(source_text: text).call.rendered_text
    puts "Rendered text:\n=======\n\n #{rendered_text}\n=========\n\n"
    UserRepository.all.each do |user|
      if !(['dilibop', 'jc'].include? user.username)
        puts "EDIT #{user.username}"
        document = DocumentRepository.find_by_title "#{user.username}.home"
        puts "  -- confirm: document = #{document.title}"
        document.text = text
        document.rendered_text = rendered_text
        DocumentRepository.update document
      end
    end
  end


end
