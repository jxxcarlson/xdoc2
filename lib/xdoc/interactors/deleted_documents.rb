require 'hanami/interactor'



class DeletedDocuments
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


  def user_search(username)
    user = UserRepository.find_by_username(username)
    puts "user_search, user = #{user.username}"
    puts "user_search, user id = #{user.id}"
    if user == nil
      return [ ]
    end
    @documents = DocumentRepository.find_by_owner(user.id) || []
    @document_hash_array = @documents.map { |document| document ? document.short_hash : 'null'}.select{|x| x != 'null'}
    @document_hash_array = @document_hash_array.select(&deleted_filter)
  end


  ######## FILTER ########


  def deleted_filter
    lambda{ |dochash| dochash[:status] == 'deleted' }
  end

  def user_id(key)
    if key =~ /[0-9].*/
      key
    else
      user = UserRepository.find_by_username key
      user.id
    end
  end

  def filter_hash_array
    @queries.each do |query|
      @document_hash_array = apply_filter(query, @document_hash_array)
    end
    @document_hash_array = @document_hash_array.select(&not_deleted_filter)
  end

  def set_id_array
    @id_array = @document_hash_array.map{ |hash| hash[:id] }
  end

  ######## CALL ########

  def call
    puts 'List deleted documents ...'
    parse
    _command, user = @queries.shift
    user_search(user)
    @document_count = @documents.count
  end
end

