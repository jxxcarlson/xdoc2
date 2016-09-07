require 'hanami/interactor'
require_relative 'identifier'



class CreateDocument

  include Hanami::Interactor


  expose :new_document, :parent_document, :status

  def initialize(params, author_id)
    @params = params
    @author_id = author_id
    opts = params['options'] || ""
    if opts.length < 5
      @options = {}
    else
      @options = JSON.parse(opts)
    end
  end

  def create
    document = NSDocument.new(@params)
    author = UserRepository.find @author_id
    document.owner_id = author.id
    document.author_name = author.username
    document.text = "(Dummy text for ew document #{document.title})"
    document.rendered_text = "(Dummy text for new document #{document.title})"

    document.kind = author.get_preference('doc_format') || 'asciidoc'

    puts "*** Document #{document.title} created as #{document.kind}"

    @new_document = DocumentRepository.create document

    Identifier.new(nil, @new_document).call
    puts "CreateDocument: created #{@new_document.title} (#{@new_document.id})"
    @status = 'success'
  end

  def attach

    puts 'Entering attach document'
    puts "  @options = #{@options}"
    puts "  @options = #{@options.inspect}"
    puts "  @options = #{@options.class.name}"


    puts "  @options['child'] = #{@options['child']}"
    puts "  @options['position'] = #{@options['position']}"

    if @options['child'] == true

      @parent_document = DocumentRepository.find @params['current_document_id']
      if @parent_document
        puts "I am going attach a new sibling #{@new_document.title } of #{@parent_document.title}"
        @parent_document.adopt_child @new_document
        DocumentRepository.update @parent_document
        puts "CreateDocument: attached #{@new_document.title} to #{@parent_document.title}"
        @status = 'success'
      else
        @status = 'error'
      end
    end

    if (@options['position'] == 'above') || (@options['position'] == 'below')


      @parent_document = DocumentRepository.find @params['parent_document_id']
      current_document = DocumentRepository.find @params['current_document_id']
      puts "\nI am going attach a new sibling #{@new_document.title } of #{current_document.title}\n"

      if @parent_document == nil or current_document == nil
        @status = 'error, could not attach document'
      else

        documents = @parent_document.links || []
        last_index = documents.count
        @parent_document.adopt_child @new_document
        puts "\nCreateDocument: attached #{@new_document.title} to #{@parent_document.title}\n"
        target_index = @parent_document.index_of_subdocument current_document
        target_index += 1 if @options['position'] == 'below'
        @parent_document.move_subdocument(last_index, target_index)
        puts "\nCreateDocument: move #{@new_document.title} to index #{target_index} of #{@parent_document.title}\n"

        DocumentRepository.update @parent_document
        @status = 'success'
      end

    end

  end

  def call
    create
    attach
  end

end




