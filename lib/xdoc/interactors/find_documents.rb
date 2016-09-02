require 'hanami/interactor'


# The FindDocument interactor authenticates
#
# Search language -- query elements
#
# A query is of the form TERM, TERM&TERM, etc.
# A TERM is of the form COMMAND=ARG
#
# EXAMPLES:
#
#     scope=all
#     scope=public
#     user=baz
#     title=mech
#     tag=physics
#     user.title=baz.mech  -- return user baz's files which contain 'mech' in the title
#                          -- search is case insensitive
#     user.public=baz      -- return articles that are public or belong to baz
#
#
# scope=all
# scope=public
# scope=user.baz # return records for user baz
#
# title=mech   # Return 'Quantum Mechanics' and 'mechanical toys'
#
# To do
# #####
#
# Query elements should be composable without regard to order, e.g.
#
# scope=public&title=mech&tag=atom&title=electro
#
# In this example, the public records with tag=atom
# and title containing both 'mech' and 'electro', with
# the search being case insensitive
#
class FindDocuments
  include Hanami::Interactor

  expose :documents, :document_count, :document_hash_array, :first_document

  def initialize(query_string, access)
    @query_string = query_string.downcase
    @access = access
    @documents = []
    @status = 400
  end

  def parse
    @queries = @query_string.split('&').map{ |item| item.split('=')}
  end

  ######## SEARCH ########

  def all_documents
    @documents = DocumentRepository.all
  end

  def public_documents
    @documents = DocumentRepository.find_public
    @documents = @documents.all.select{ |doc| doc.parent_id == 0}
  end

  def user_search(username)
    user = UserRepository.find_by_username(username)
    @documents = DocumentRepository.find_by_owner(user.id)
    @documents = @documents.all.select{ |doc| doc.parent_id == 0}
  end

  def scope_search(arg)
    case arg
      when 'all'
        all_documents
      when 'public'
        public_documents
      else
        all_documents
    end
  end

  def user_title_search(arg)
    username, title = arg.split('.')
    user = UserRepository.find_by_username(username)
    @documents = DocumentRepository.find_by_owner_and_fuzzy_title(user.id, title)
  end

  # command: 'shared=user,group'
  # example: 'shared=jc,test'
  def shared_search(arg)
    user_name, group = arg.split(',')
    puts "\n\nuser_name = #{user_name}"
    puts "\n\ngroup = #{group}"
    user = UserRepository.find_by_username user_name
    puts "user.has_acl? group = #{user.has_acl group}"
    @documents = [] if !(user.has_acl group)
    DocumentRepository.all.select{ |doc| doc.has_acl(group)}
  end

  def user_public_search(arg)
    username, title = arg.split('.')
    user = UserRepository.find_by_username(username)
    @documents = DocumentRepository.find_public_by_owner(user.id)
  end

  def title_search(arg)
    @documents = DocumentRepository.fuzzy_find_by_title(arg)
  end

  def id_search(arg)
    @documents = [DocumentRepository.find(arg)]
  end

  def tag_search(arg)
    @documents = DocumentRepository.find_by_tag(arg)
  end

  def random_search(percentage)
    n = ENV['DEFAULT_DOCUMENT_ID']
    @documents = DocumentRepository.random_sample(percentage).select{ |doc| doc.id != n}[0..50]
  end
  def search(query)
    @command, arg = query
    case @command
      when 'scope'
        scope_search(arg)
      when 'user'
        user_search(arg)
      when 'shared'
        shared_search(arg)
      when 'title'
        title_search(arg)
      when 'user.title'
        user_title_search(arg)
      when 'user.public'
        user_public_search(arg)
      when 'id'
        id_search(arg)
      when 'tag'
        tag_search(arg)
      when 'random'
        random_search(arg)
    end
    @document_hash_array = @documents.map { |document| document ? document.short_hash : 'null'}.select{|x| x != 'null'}
  end

  ######## FILTER ########

  def user_filter(owner_id)
    lambda{ |dochash| dochash[:owner_id] == owner_id }
  end

  def user_or_public_filter(owner_id)
    lambda{ |dochash| ( (dochash[:public] == true) || (dochash[:owner_id] == owner_id) ) }
  end

  def public_filter
    lambda{ |dochash| dochash[:public]  == true }
  end

  def title_filter(arg)
    lambda{ |dochash| dochash[:title].downcase =~ /#{arg}/ }
  end

  def user_id(key)
    if key =~ /[0-9].*/
      key
    else
      user = UserRepository.find_by_username key
      user.id
    end
  end


  def apply_filter(query, hash_array)

    command, arg = query

    case command
      when 'scope'
        case arg
          when 'public'
            hash_array = hash_array.select(&public_filter)
          else
        end
      when 'user'
        id = user_id(arg)
        hash_array = hash_array.select(&user_filter(id))
      when 'user.public'
        id = user_id(arg)
        hash_array = hash_array.select(&user_or_public_filter(id))
      when 'title'
        hash_array = hash_array.select(&title_filter(arg))
    end
    hash_array
  end

  def filter_hash_array
    @queries.each do |query|
      @document_hash_array = apply_filter(query, @document_hash_array)
    end
  end

  def set_id_array
    @id_array = @document_hash_array.map{ |hash| hash[:id] }
  end

  def filter_documents
    set_id_array
    if @documents.class.name == 'Array'
      @documents = @documents.select{ |doc| @id_array.include?(doc.id) }
    else
      @documents = @documents.all.select{ |doc| @id_array.include?(doc.id) }
    end
  end

  def apply_permissions
    if @access == nil || @access.username == nil
      @queries << ["scope", "public"]
    else
      @queries << ["user.public", @access.username]
    end
  end

  def normalize

  end

  def get_first_document
    @first_document = @documents[0]
  end

  def handle_empty_search_result
    if @documents == []
      default_document = DocumentRepository.find(ENV['DEFAULT_DOCUMENT_ID'])
      @documents = [default_document]
      @document_hash_array = @documents.map { |document| document.short_hash }
    end
  end

  def trim_random_sample
    if @command == 'random'
      @document_hash_array = @document_hash_array[0..4]
    end
  end


  ######## CALL ########

  def call
    parse
    # apply_permissions
    normalize
    query = @queries.shift
    search(query)
    filter_hash_array
    trim_random_sample
    filter_documents
    handle_empty_search_result
    get_first_document
    @document_count = @documents.count
  end
end

