require_relative '../../../../lib/xdoc/modules/verify'
require_relative '../../../../lib/xdoc/interactors/grant_access'

module Api::Controllers::Images
  class Create
    include Api::Action
    include Permission

    def create_image
      message = "Image controller, owner = #{params[:owner]}, url: #{params[:url]}"
      puts message
      url = "http://psurl.s3.amazonaws.com/#{params[:filename]}"
      user = UserRepository.find_by_username(params[:owner])
      image = Image.new(url: url,
                        title: params[:title],
                        content_type: params[:content_type],
                        owner_id: user.id,
                        source: params[:source])
      image = ImageRepository.create(image)


      if params[:attach]
        puts "--- params[:content_type] = #{params[:type]}"
        result =  CreateDocument.new({title: params[:title], kind: params[:type]}, @access.user_id).call
        document = result.new_document
        resources = document.links['resources'] || {}
        media_resource = {'id' => image.id, 'media_type' => image.content_type, 'url' => image.url}
        resources['media_attachment'] = media_resource
        document.links['resources'] = resources
        document = DocumentRepository.update document
        puts "Document #{document.id} created with resource #{media_resource}"

        reply =  { 'status': 'success', 'title': image.title, 'id': image.id,
                   'url': image.url, source: image.source,
                   'content_type': image.content_type, 'parent_document': document.id }.to_json
      else
        reply =  { 'status': 'success', 'title': image.title, 'id': image.id,
                   'url': image.url, source: image.source,
                   'content_type': image.content_type, 'parent_document': 0 }.to_json
      end
      

       puts "REPLY in image creation with attachment:  #{reply}"
       self.body = reply
    end

    def call(params)

      puts "IMAGE controller CREATE, ATTACH = #{params[:attach]}"

      token = request.env["HTTP_ACCESSTOKEN"]
      @access = GrantAccess.new(token).call

      if @access.valid
        create_image
      else
        deny_access
      end


    end
  end
end
