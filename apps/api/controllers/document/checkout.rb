module Api::Controllers::Document
  class Checkout
    include Api::Action

    def call(params)
      self.body = 'OK'
    end
  end
end
