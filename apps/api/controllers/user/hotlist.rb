module Api::Controllers::User
  class Hotlist
    include Api::Action

    def call(params)
      self.body = 'OK'
    end
  end
end
