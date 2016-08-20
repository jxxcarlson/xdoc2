require_relative '../../../../lib/xdoc/interactors/update_image'

module Api::Controllers::Images
  class Update
    include Api::Action

    # this is fake commment #
    
    def call(params)
      puts "API: image update"

      puts "id: #{params[:id]}"
      puts "title: #{params[:title]}"
      puts "source: #{params[:source]}"
      puts "tags: #{params[:tags]}"

      verify_request(request)

      if @access.valid

        result = UpdateImage.new(params).call
        if result.status == 'success'
          self.body = {status: 'success', image: result.hash}.to_json
          puts "RESPONSE, hash = #{result.hash}"
        else
          self.body = {status: 'error'}.to_json
        end

      else
       self.body = {status: 'error'}.to_json
      end

    end


    def verify_csrf_token?
      false
    end

  end
end
