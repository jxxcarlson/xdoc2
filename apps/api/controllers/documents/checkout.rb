module Api::Controllers::Documents
  class Checkout
    include Api::Action

    def call(params)
      result = CheckoutManager.new(request.query_string).call
      self.body = {status: 'success', query: request.query_string, reply: result.reply }.to_json
    end
  end
end
