require 'hanami/interactor'

require_relative '../../xdoc/classes/hash_array'

include XDoc

class HotListManager
  include Hanami::Interactor

  expose :hotlist

  def initialize(user, command, document = nil)
    @user = user
    @document = document
    @command = command
    dict = @user.dict || {}
    @hotlist = dict['hotlist'] || []
    @ha = HashArray.new(@hotlist, 7)
  end

  def push
    @ha.push_unique @document.short_hash, 'id'
    @hotlist = @ha.items
    dict = @user.dict || {}
    dict['hotlist'] = @hotlist
    @user.dict = dict
    UserRepository.update @user
  end

  def get

  end

  def call
    send @command
  end

end

