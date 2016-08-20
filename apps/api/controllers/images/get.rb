

module Api::Controllers::Images
  class Get
    include Api::Action



    def call(params)
      id = params['id']
      image = ImageRepository.find(id)
      if image
        # response.status = 200
        hash = {'response' => 'success', 'image' => image.hash }
        self.body = hash.to_json
      else
        # response.status = 500
        self.body = { "error" => "500 Server error: document not found or processed" }.to_json
      end
    end

  end
end
