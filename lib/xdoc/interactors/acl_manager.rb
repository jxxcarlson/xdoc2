require 'hanami/interactor'



class ACLManager

  include Hanami::Interactor

  expose :commands, :status

  def initialize(command)
    @commands = command.split('&').map{|command| command.split('=')} || []
    @queue = @commands.dup
    puts "\ncommands = #{@commands}\n\n"
    @status = 'error'
  end

  def create_acl
    puts "\nverb = #{@verb}, object = #{@object}\n\n"
    verb, permission = @commands.shift
    @status = 'success'
  end

  def remove_acl
    puts "\nverb = #{@verb}, object = #{@object}\n\n"
    @status = 'success'
  end

  def add_user
    puts "\nverb = #{@verb}, object = #{@object}\n\n"
    @status = 'success'
  end

  def remove_user
    puts "\nverb = #{@verb}, object = #{@object}\n\n"
    @status = 'success'
  end

  def add_document
    puts "\nverb = #{@verb}, object = #{@object}\n\n"
    @status = 'success'
  end

  def remove_document
    puts "\nverb = #{@verb}, object = #{@object}\n\n"
    @status = 'success'
  end

  def request_permission
    puts "\nverb = #{@verb}, object = #{@object}\n\n"
    @status = 'success'
  end

  def call

    return if @queue == []

    @verb, @object = @queue.shift
    return if !(['create_acl', 'remove_acl', 'add_user', 'remove_user', 'add_document', 'remove_document', 'request_permission'].include? @verb)

    if @queue != []

      send @verb
    end

  end

end
