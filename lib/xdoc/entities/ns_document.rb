class NSDocument
  include Hanami::Entity

  attributes :id, :identifier, :owner_id, :author_name, :collection_id, :title,
             :created_at, :updated_at, :viewed_at, :visit_count,
             :text, :rendered_text, :public, :dict, :kind, :links, :tags

  def initialize(attributes = {})
    super
    @text ||= ''
    @rendered_text ||= ''
    @public ||= false
    @dict  ||= {}
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
      { 'id': self.id,
        'identifier': self.identifier,
        'title': self.title,
        'kind': self.kind,
        'tags': self.stringify_tags,
        'has_subdocuments': self.has_subdocuments,
        'url': "/documents/#{self.id}",
        'owner_id': self.owner_id,
        'author': self.author_name,
        'public': self.public,
        'created_at': self.created_at,
        'updated_at':  self.updated_at,
        'text': self.text,
        'rendered_text': self.rendered_text,
        'links': self.links
      }
  end

  # Does not include text and rendered text
  def short_hash
    { 'id': self.id,
      'identifier': self.identifier,
      'title': self.title,
      'has_subdocuments': self.has_subdocuments,
      'url': "/documents/#{self.id}",
      'owner_id': self.owner_id,
      'author': self.author_name,
      'public': self.public,
      'created_at': self.created_at,
      'updated_at':  self.updated_at,
      'kind': self.kind,
      'tags': self.stringify_tags,
      'links': self.links
    }
  end


  def minimal_hash
    { 'id': self.id,
      'identifier': self.identifier,
      'title': self.title,
      'url': "/documents/#{self.id}",
      'owner_id': self.owner_id,
      'author': self.author_name,
      'public': self.public,
    }
  end

  # Like above, but a hack to solve the :id vs 'id' problem -- BAAD!
  def short_hash2
    { 'id' => self.id,
      'identifier' => self.identifier,
      'title' => self.title,
      'has_subdocuments' => self.has_subdocuments,
      'url' => "/documents/#{self.id}",
      'owner_id' => self.owner_id,
      'author' => self.author_name,
      'public' => self.public,
      'created_at' => self.created_at,
      'updated_at' =>  self.updated_at,
      'kind' => self.kind,
      'tags' => self.stringify_tags,
      'links' => self.links
    }
  end

  def update_from_hash(hash)

    puts "update_from_hash: #{hash.to_s}"

    self.title = hash['title'] if hash['title']
    self.identifier = hash['identifier'] if hash['identifier']
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
    self.links['resources'] = hash['links']['resources'] if hash['links'] && hash['links']['resources']
    self.update_tags_from_string hash['tags'] if hash['tags']
    DocumentRepository.update  self
  end


  ###
  ### Manage Parents and Children
  ###

  # Append the hash representation of doc
  # to the array "documents" of the hash
  # self.links
  def adopt_child(child)
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

  def unlink
    # remove oneself from parent
    self.parent.remove_child(self) if self.parent

    # remove parent of chldren
    children = self.subdocuments.map{ |subdoc| DocumentRepository.find subdoc[:id]}
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
    self.subdocuments.map{ |x| x['title'] || x[:title]}
  end

  def child_ids
    self.subdocuments.map{ |x| x['id'] || x[:id]}
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
    self.subdocuments.map{ |sd| sd['id']}
  end

  def verify_parent_for_children
    self.subdocuments.each do |hash|
      document = DocumentRepository.find hash['id']
      if document.links['parent']['id'] ==  self.id
        puts "#{hash['id']} - #{hash['title']}: ok"
      else
        puts "#{hash['id']} - #{hash['title']}: FAIL"
      end
      DocumentRepository.update document
    end
    self.subdocuments.map{ |sd| sd['id']}
  end


  ###########




  def update_document_links
    # first filter out bad data (and throw it away):
    subdocs = self.subdocuments.select{ |x| x != nil}
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
    puts "before move: #{subdocs.map{|x| x['id']}}"
    NSDocument.move(subdocs, from, to)
    puts "after move: #{subdocs.map{|x| x['id']}}"
    self.links['documents'] = subdocs
    DocumentRepository.update self
  end

  def move_up(subdocument)
    k = index_of_subdocument(subdocument)
    if k > 0
      self.move_subdocument(k,k-1)
    end
  end


  def move_down(subdocument)
    k = index_of_subdocument(subdocument)
    last_index = self.subdocuments.count - 1
    if k < last_index
      self.move_subdocument(k,k+1)
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

  def acl_lists
    dict = self.dict || {}
    dict['acl'] || dict[:acl]
  end






end
