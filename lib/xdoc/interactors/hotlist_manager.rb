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
    @ha = HashArray.new(@hotlist, 12)
  end

  def push
    hash = { 'id' => @document.id,
             'title' => @document.title,
             'author'=> @document.author_name,
             'url' => "documents/#{@document.id}?toc"
    }
    # @ha.push_unique @document.short_hash, 'id'
    @ha.push_unique hash, 'id'
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

