require 'hanami/interactor'


# Input:  source_text
# Output: rendered_text
class RenderAsciidoc
  include Hanami::Interactor
  include Asciidoctor

  expose :rendered_text, :image_map

  def initialize(hash)
    @source_text = hash[:source_text] || hash['source_text']
    @new_options = hash[:options] || hash['options'] || {}
  end

  def add_attributes
    @source_text = ":source-highlighter: coderay\n\n" + @source_text
  end

  def process_xrefs
    scanner = @source_text.scan /xref::(.*?)\[(.*?)\]/
    scanner.each do |item|
      id, label = item
      old_ref = "xref::#{id}[#{label}]"
      # new_ref = "http://jxxmbp.local:3000/documents/#{id}[#{label}]"
      new_ref = "#{ENV['HOST']}/documents/#{id}[#{label}]"
      puts "old_ref: #{old_ref}"
      puts "new_ref: #{new_ref}"
      @source_text = @source_text.sub(old_ref, new_ref)
    end
  end

  def process_images
    @image_map = { }
    scanner = @source_text.scan /(image|video|audio)::([0-9]*?)\[(.*?)\]/
    scanner.each do |item|
      media_type, id, label = item
      old_ref = "#{media_type}::#{id}[#{label}]"
      image = ImageRepository.find id
      if image
        @image_map[id] = {'url': image.url, 'title': image.title}
        new_ref = "#{media_type}::#{image.url}[#{label}]"
        @source_text = @source_text.sub(old_ref, new_ref)
      end
    end
  end

  def process_includes
    scanner = @source_text.scan /include::(.*?)\[(.*?)\]/
    scanner.each do |item|
      id, label = item
      old_ref = "include::#{id}[#{label}]"
      insertion_snippet = SnippetRepository.find id
      if insertion_snippet
        insertion_text = insertion_snippet.text
        @source_text = @source_text.sub(old_ref, insertion_text)
      end
    end
  end

  def preprocess
    add_attributes
    process_xrefs
    process_images
    # process_includes
  end

  def call
    base_options = { :safe => :safe, :source_highlighter => :coderay, :coderay_css => :class }
    options = base_options.merge @new_options
    preprocess
    @rendered_text = ::Asciidoctor.convert(@source_text, options)
    # @rendered_text = { rendered_text: ::Asciidoctor.convert(@source_text, options)}.to_json
  end

end


