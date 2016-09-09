module Api::Controllers::Users
  class Manage
    include Api::Action

    def call(params)
      command = request.query_string
      puts "User command: #{command}"
      result = ManageUsers.new(command).call
      puts "=============="
      puts "#{{status: result.status, list: result.user_list}}"
      self.body = {status: result.status, list: result.user_list}.to_json
    end
  end
end
