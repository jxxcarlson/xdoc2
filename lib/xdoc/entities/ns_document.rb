class NSDocument
  include Hanami::Entity


  ##
  ## self.links['documents'] = array of short_hashes of documents

  attributes :id, :identifier, :owner_id, :author_name, :collection_id, :title,
             :created_at, :updated_at, :viewed_at, :visit_count,
             :text, :rendered_text, :public, :dict, :kind, :links, :tags, :backup_number

  def initialize(attributes = {})
    super
    @text ||= ''
    @rendered_text ||= ''
    @public ||= false
    @dict ||= {}
    @kind ||= 'text'
    @links ||= {}
    @tags ||= []
  end

  def set_links_from_array(array_name, array)
    @links[array_name] = array
  end

  def set_links_from_json(array_name, str)
    @links[array_name] = JSON.parse(str)
  end


  def get_links(array_name)
    @links[array_name]
  end


  ###
  ### JSON & Hashes
  ###

  def to_hash
    hash = {}
    hash['id'] = self.id
    hash['identifier'] = self.identifier
    hash['collection_id'] = self.collection_id

    hash['title'] = self.title

    hash['created_at'] = self.created_at.to_s
    hash['updated_at'] = self.updated_at.to_s
    hash['viewed_at'] = self.viewed_at.to_s
    hash['visit_count'] = self.visit_count

    hash['kind'] = self.kind
    hash['text'] = self.text
    hash['rendered_text'] = self.rendered_text

    hash['public'] = self.public
    hash['dict'] = self.dict
    hash['links'] = self.links
    hash['tags'] = self.stringify_tags
    hash
  end

  def to_json
    self.to_hash.to_json
  end

  def update_from_json(str)
    hash = JSON.parse(str)
    self.update_from_hash(hash)
  end


  ## document API:
  def hash
    {'id': self.id,
     'identifier': self.identifier,
     'title': self.title,
     'kind': self.kind,
     'has_subdocuments': self.has_subdocuments,
     'url': "/documents/#{self.id}",
     'owner_id': self.owner_id,
     'author': self.author_name,
     'public': self.public,
     'created_at': self.created_at,
     'updated_at': self.updated_at,
     'text': self.text,
     'rendered_text': self.rendered_text,
     'links': self.links,
     'dict': self.dict,
     'tags': self.stringify_tags
    }
  end

  def public_hash
    {'id': self.id,
     'identifier': self.identifier,
     'title': self.title,
     'kind': self.kind,
     'has_subdocuments': self.has_subdocuments,
     'url': "/documents/#{self.id}",
     'owner_id': self.owner_id,
     'author': self.author_name,
     'public': self.public,
     'created_at': self.created_at,
     'updated_at': self.updated_at,
     'text': self.text,
     'rendered_text': self.rendered_text,
     'links': self.public_links,
     'dict': self.dict,
     'tags': self.stringify_tags
    }
  end

  def public_links
    public_documents = []
    if self.links['documents']
      self.links['documents'].each do |doc|
        public_documents << doc if doc['public']
      end
    end

    { 'parent' => self.parent_hash, 'documents' => public_documents}
  end

  # Does not include text and rendered text
  def short_hash
    dict = self.dict || {}
    {'id': self.id,
     'identifier': self.identifier,
     'title': self.title,
     'has_subdocuments': self.has_subdocuments,
     'url': "/documents/#{self.id}",
     'owner_id': self.owner_id,
     'author': self.author_name,
     'public': self.public,
     'created_at': self.created_at,
     'updated_at': self.updated_at,
     'kind': self.kind,
     'tags': self.stringify_tags,
     'links': self.links,
     'checked_out_to': dict['checked_out_to'] || '',
     'status': dict['status']
    }
  end


  def minimal_hash
    {'id': self.id,
     'identifier': self.identifier,
     'title': self.title,
     'url': "/documents/#{self.id}",
     'owner_id': self.owner_id,
     'author': self.author_name,
     'public': self.public
    }
  end

  # Like above, but a hack to solve the :id vs 'id' problem -- BAAD!
  def short_hash2
    {'id' => self.id,
     'identifier' => self.identifier,
     'title' => self.title,
     'has_subdocuments' => self.has_subdocuments,
     'url' => "/documents/#{self.id}",
     'owner_id' => self.owner_id,
     'author' => self.author_name,
     'public' => self.public,
     'created_at' => self.created_at,
     'updated_at' => self.updated_at,
     'kind' => self.kind,
     'tags' => self.stringify_tags,
     'checked_out_to'=> dict['checked_out_to'] || '',
     'links' => self.links
    }
  end

  def update_from_hash(hash)

    puts "DEBUG update doc: update_from_hash .."
    puts "DEBUG -- title = #{hash['title']}"
    puts "DEBUG -- owner_id = #{hash['owner_id']}"

    self.title = hash['title'] if hash['title']

    if hash['identifier']
      Identifier.new(hash['identifier'], self).call
    end

    self.owner_id = hash['owner_id'] if hash['owner_id']
    self.collection_id = hash['collection_id'] if hash['collection_id']

    self.updated_at = Time.now.utc.iso8601
    self.viewed_at = hash['viewed_at'] if hash['viewed_at']
    self.visit_count = hash['visit_count'] if hash['visit_count']

    self.kind = hash['kind'] if hash['kind']
    self.text = hash['text'] if hash['text']
    self.rendered_text = hash['rendered_text'] if hash['rendered_text']

    self.public = hash['public'] if hash['public'] != nil

    self.dict = hash['dict'] if hash['dict']
    self.links['documents'] = hash['links']['documents'] if hash['links'] && hash['links']['documents']
    self.update_tags_from_string hash['tags'] if hash['tags']
    DocumentRepository.update self
  end


  ###
  ### Manage Parents and Children
  ###

  # Append the hash representation of doc
  # to the array "documents" of the hash
  # self.links
  def adopt_child(child)
    # do not proceed if the child has already been adopted
    return if self.child_ids.include? child.id

    # point the parent link of the child to the parent
    parent = self
    child.links['parent'] = parent.minimal_hash
    DocumentRepository.update child

    # Add an entry in the parent to point to the child
    parent.links ||= {}
    parent.links['documents'] ||= []
    parent.links['documents'] << child.short_hash
    DocumentRepository.update parent
  end

  def parent_id
    parent_hash['id'] || parent_hash[:id] || 0
  end

  def parent_hash
    self.links['parent'] || {}
  end

  def parent_name
    parent_hash['title'] || parent_hash[:title] || ''
  end

  def parent
    DocumentRepository.find self.parent_id
  end

  def remove_parent
    self.links['parent'] = {}
    DocumentRepository.update self
  end

  def remove_child(child)
    if child.class == Integer
      child = DocumentRepository.find child
    end
    index_of_child = self.index_of_subdocument(child)
    documents = self.links['documents']
    documents.delete_at index_of_child
    self.links['documents'] = documents
    DocumentRepository.update self
  end

  def remove_children
    names = self.child_names
    self.links['documents'] = []
    DocumentRepository.update self
    names
  end

  def unlink_from_parent
    # remove oneself from parent
    self.parent.remove_child(self) if self.parent

    # remove parent
    self.remove_parent
  end

  # remove from parent and remove children
  def unlink
    # remove oneself from parent
    self.parent.remove_child(self) if self.parent

    # remove parent of chldren
    children = self.subdocuments.map { |subdoc| DocumentRepository.find subdoc[:id] }
    children.each do |child|
      child.remove_parent
    end

    # remove parent
    self.remove_parent
    self.remove_children
  end

  def self.delete(doc)
    doc.unlink
    DocumentRepository.delete doc
  end

  def subdocuments
    self.links['documents'] || []
  end

  def child_names
    self.subdocuments.map { |x| x['title'] || x[:title] }
  end

  def child_ids
    self.subdocuments.map { |x| x['id'] || x[:id] }
  end

  def has_subdocuments
    self.subdocuments != []
  end

  def set_parent_for_children
    self.subdocuments.each do |hash|
      puts "#{hash['id']}: #{hash['title']}"
      document = DocumentRepository.find hash['id']
      document.links['parent'] = self.minimal_hash
      DocumentRepository.update document
    end
    self.subdocuments.map { |sd| sd['id'] }
  end

  def verify_parent_for_children
    self.subdocuments.each do |hash|
      document = DocumentRepository.find hash['id']
      if document.links['parent']['id'] == self.id
        puts "#{hash['id']} - #{hash['title']}: ok"
      else
        puts "#{hash['id']} - #{hash['title']}: FAIL"
      end
      DocumentRepository.update document
    end
    self.subdocuments.map { |sd| sd['id'] }
  end


  ###########


  def update_document_links
    # first filter out bad data (and throw it away):
    subdocs = self.subdocuments.select { |x| x != nil }
    subdocs_new = []
    subdocs.each do |dochash|
      valid = true
      id = dochash[:id] || dochash['id']
      valid = false if id == nil
      if valid
        doc = DocumentRepository.find id
        valid = false if doc == nil
      end
      subdocs_new << doc.short_hash2 if valid
    end
    self.links['documents'] = subdocs_new
    DocumentRepository.update self
    "#{subdocs.count} => #{subdocs_new.count}"
  end

  def stringify_tags
    str = ''
    tags = self.tags
    if tags.count > 0
      self.tags[0..-2].each do |tag|
        str += tag + ', '
      end
      str += tags[-1]
    end
    str
  end

  def update_tags_from_string(str)
    self.tags = str.gsub(' ', '').split(',')
    DocumentRepository.update self
  end

  def self.move(array, from, to)
    item = array[from]
    if from > to
      array.insert(to, item)
      array.delete_at(from+1)
    else
      array.insert(to+1, item)
      array.delete_at(from)
    end
    array
  end

  def move_subdocument(from, to)
    subdocs = self.subdocuments
    puts "before move: #{subdocs.map { |x| x['id'] }}"
    NSDocument.move(subdocs, from, to)
    puts "after move: #{subdocs.map { |x| x['id'] }}"
    self.links['documents'] = subdocs
    DocumentRepository.update self
  end

  def move_last_subdocument(to)
    subdocs = self.subdocuments
    n = subdocs.count - 1
    puts "before move: #{subdocs.map { |x| x['id'] }}"
    NSDocument.move(subdocs, n, to)
    puts "after move: #{subdocs.map { |x| x['id'] }}"
    self.links['documents'] = subdocs
    DocumentRepository.update self
  end

  def move_up(subdocument)
    k = index_of_subdocument(subdocument)
    if k > 0
      self.move_subdocument(k, k-1)
    end
  end


  def move_down(subdocument)
    k = index_of_subdocument(subdocument)
    last_index = self.subdocuments.count - 1
    if k < last_index
      self.move_subdocument(k, k+1)
    end
  end

  def index_of_subdocument(subdocument)
    subdocument_id = subdocument.id
    idx = -1
    self.links['documents'].each_with_index do |doc, index|
      if doc['id'] == subdocument_id
        idx = index
        break
      end
    end
    idx
  end

  def acls
    dict = self.dict || {}
    dict['acl'] || dict[:acl] || []
  end

  def has_acl(name)
    self.acls.include? name
  end


  def join_acl(name)
    acl = AclRepository.find_by_name(name)
    return if acl == nil
    return if !(acl.contains_document(self.id))
    dict = self.dict || {}
    my_acls = dict['acl'] || []
    if !(my_acls.include? name)
      my_acls << name
      self.dict ||= {}
      self.dict['acl'] = my_acls
      DocumentRepository.update self
    end
  end

  def leave_acl(name)
    acl = AclRepository.find_by_name(name)
    puts 'A'
    return if acl == nil
    puts 'B'
    dict = self.dict || {}
    my_acls = dict['acl'] || []
    if my_acls.include? name
      puts 'D'
      my_acls.delete name
      self.dict['acl'] = my_acls
      DocumentRepository.update self
    end
  end

  def put_backup_info(number, date)
    dict = self.dict || {}
    dict['backup'] = {'number' => number, 'date' => date.to_s}
    self.dict = dict
    DocumentRepository.update self
  end

  def get_backup_info
    dict = self.dict || {}
    return dict['backup'] || {}
  end

  def get_backup_number
    get_backup_info['number'] || 0
  end

  ##
  ## Check document in/out
  ##

  def checked_out_to
    dict = self.dict || {}
    return dict['checked_out_to'] || ''
  end

  def check_out_to(username)
    dict = self.dict || {}
    dict['checked_out_to'] ||= ''
    if dict['checked_out_to'] == ''
      dict['checked_out_to'] = username
      self.dict = dict
      DocumentRepository.update self
      return username
    else
      return 'error'
    end
  end

  def check_in_by(username)
    dict = self.dict || {}
    if self.author_name == username || dict['checked_out_to'] == username
      puts "CHECKDNG IN (2)"
      dict['checked_out_to'] = ''
      self.dict = dict
      DocumentRepository.update self
      return 'checked_in'
    else
      return 'error'
    end
  end

  def checkout_toggle(username)
    puts "checkout_toggle, username = #{username}"
    status = self.checked_out_to
    puts "checkout_toggle, status = #{status}"
    if status == ''
      self.check_out_to(username)
      return username
    end
    if status == username || self.author_name == username
      puts "CHECKDNG IN (1)"
      self.check_in_by(username)
      return 'checked_in'
    end
    return 'error'
  end

  # status values: 'deleted'
  def status
    dict = self.dict || {}
    dict['status']
  end

  def set_status(value)
    dict = self.dict || {}
    dict['status'] = value
    self.dict = dict
    DocumentRepository.update self
  end


end
