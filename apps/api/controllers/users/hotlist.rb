require_relative '../../../../lib/xdoc/interactors/hotlist_manager'



module Api::Controllers::Users

  class Hotlist
    include Api::Action

    def call(params)
      puts "Called hotlist"
      username = params[:username]
      puts "Called hotlist for user #{username}"
      user = UserRepository.find_by_username username
      return if user == nil
      hotlist = HotListManager.new(user, 'get').call.hotlist || []
      reply = { 'status' => 'success', 'hotlist' => hotlist}
      self.body = reply.to_json
    end

  end


end
