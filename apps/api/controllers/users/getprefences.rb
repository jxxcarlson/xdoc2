module Api::Controllers::Users
  class Getprefences
    include Api::Action

    def call(params)
      user = UserRepository.find_by_username params[:id]
      self.body = user.dict.to_json
    end
  end
end
