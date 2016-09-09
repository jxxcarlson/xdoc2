
require 'hanami/interactor'


#
class ManageUsers
  include Hanami::Interactor

  expose :status, :user_list

  def initialize(command)
    puts "ManageUsers, command = #{ManageUsers}"
    @commands = command.split('&').map{ |command| command.split('=') }
    @status = 'error'
  end

  def list
    array =[]
    puts "empty array"
    puts "Manage users, list .. "
    UserRepository.all.each do |user|
      array << user.hash
      puts array
    end
    @user_list = array
    @status  = 'success'
  end

  def call
    @verb, @object = @commands.shift
    puts "ManageUsers, @verb = #{@verb}"
    send @verb
  end


end




