
require_relative '../../../../lib/xdoc/interactors/access_token'

module Api::Controllers::Users
  class Gettoken
    include Api::Action


    def call(params)
      result = AccessToken.new(username: params[:id], password: request.query_string).call
      user = UserRepository.find_by_username params[:id]
      puts "Gettoken called, User = ${user}"
      if user == nil
        self.body = {:status => 'error'}
      else
        # self.body = {:status => result.status, :token => result.token }.to_json

        reply = {:status => result.status, :user_id => user.id, :token => result.token,
                     :last_document_id => user.dict['last_document_id'],
                     :last_document_title => user.dict['last_document_title']}
        puts("gettoken reply: #{reply}")
        self.body = reply.to_json
      end
    end
  end
end
