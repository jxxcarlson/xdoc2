require 'hanami/interactor'


class UpdateImage
  include Hanami::Interactor

  expose :updated_image, :hash, :status

  def initialize(params)
    @params = params
  end

  def update(image)
    puts "-- la la la!"
    image.title = @params[:title] if @params[:title]
    image.source = @params[:source]if @params[:source]
    image.public = @params[:public]if @params[:public]
    image.update_tags_from_string @params[:tags] if @params[:tags]
    @updated_image = ImageRepository.update image
    @hash = image.hash.to_json
    @status = 'success'
  end

  def call
    puts "Master, this is UpdateImage.  You rang?"
    image = ImageRepository.find @params[:id]
    puts "Image title = #{image.title}"
    if image
      puts "-- Yada!"
      update(image)
    else
      @status = 'error'
    end

  end

end
