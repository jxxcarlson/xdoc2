require 'hanami/interactor'
require_relative 'render_asciidoc'


class UpdateDocument
  include Hanami::Interactor

  expose :updated_document, :hash,  :status

  def initialize(params, query_string)
    @params = params
    @document = DocumentRepository.find(@params['id'])
    @query_string = query_string || ''
  end

  def update
    if @document
      @document.update_from_hash(@params)
      result = ::RenderAsciidoc.new(source_text: @document.text).call
      @document.rendered_text = result.rendered_text
      # @document.links['images'] = result.image_map
      @updated_document = DocumentRepository.update @document
      @hash = {'status' => 'success', 'document' => @document.hash }.to_json
      @status = 'success'
    else
      @hash = { "error" => "500 Server error: document not updated" }.to_json
      @status = 'error'
    end
  end

  def attach_new_child
    puts "attach_new_child, commands =  #{@commands}"
    command = @commands.shift
    _verb, id = command.split('=')
    parent_document = DocumentRepository.find id
    puts "  -- parent_document = #{parent_document.title}"
    puts "  -- child_document  = #{@document.title}"
    if parent_document
      parent_document.adopt_child(@document)
      @updated_document = parent_document
      @hash = @updated_document.short_hash
      else @status = 'error'
    end
  end

  def attach_new_sibling
    # query_string = 'attach_to=22&as_sibling_of=88&position=above'
    command = @commands.shift
    _verb, parent_id = command.split('=')
    parent_document = DocumentRepository.find parent_id
    if parent_document
      parent_document.adopt_child(@document)
      _verb, sibling_id = command.split('=')
      sibling_document = DocumentRepository.find sibling_id
      index = parent_document.index_of_subdocument(sibling_document)
      last_index = parent.documents.subdocuments.count - 1
      parent_document.move_subdocument(last_index,index)
      @updated_document = parent_document
      @hash = @updated_document.short_hash
    else @status = 'error'
    end
  end

  def attach_document
    # query_string = 'attach_to=22' -- attach
    # current document to document with id = 22
    #
    # query_string = 'attach_to=22&as_sibling_of=88&position=above' -- attach
    # current document to document with id 22 bove sibling with id 88
    # --- similarly for position=below

    @commands = @query_string.split('&')


    case @commands.count
      when 1
        attach_new_child
      when 3
        attach_new_sibling
    end

  end

  def move_subdocument
    # query_string = 'move_up=22', where 22 is
    # the id of the subdocument to move up
    subdocument_id = @query_string.split('=')[1]
    subdocument = DocumentRepository.find(subdocument_id) if subdocument_id

    if @document && subdocument
      case @query_string
        when /up/
          @document.move_up(subdocument)
        when /down/
          @document.move_down(subdocument)
      end
      @updated_document = DocumentRepository.update @document
      @hash = {'status' => 'success', 'document' => @document.hash }.to_json
      @status = 'success'
    else
      @hash = { "error" => "500 Server error: document not updated" }.to_json
      @status = 'error'
    end
  end

  def call
    # http://blog.honeybadger.io/rubys-case-statement-advanced-techniques/
    case @query_string
      when ''
        update
      when /move/nnnnnnnnnnn
        move_subdocument
      when /attach/
        attach_document
    end
  end

end
