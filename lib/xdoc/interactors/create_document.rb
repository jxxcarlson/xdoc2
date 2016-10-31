require 'hanami/interactor'
require_relative 'identifier'

# var parameter = JSON.stringify({
# title: $scope.title, token: access_token, options: JSON.stringify($scope.formData),
#    current_document_id: self.currentDocument.id, parent_document_id: self.parent.id
# });

#  params:
#  title, token: access_token, options: formData,
#  current_document_id, parent_document_id



class CreateDocument

  include Hanami::Interactor
  include Asciidoctor


  expose :new_document, :parent_document, :status

  def initialize(params, author_id)
    @params = params
    # puts "CreateDocument, params: #{params.env['router.params']}"
    # Example: options = {"child"=>false, "position"=>"null"}
    puts "  -- title: #{params['title']}"
    puts "  -- options: #{params['options']}"
    puts "  -- current_document_id: #{params['current_document_id']}"
    puts "  -- parent_document_id: #{params['parent_document_id']}"
    puts "  -- text: #{params['text']}"

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
    default_text = "== Dummy text\n\nA stitch in time saves _nine_.\n\n"
    default_text << "== Tips\n\nSelect `Tools > View document` or type `ctrl-V` to leave the editor\n\n"
    default_text << "See the xref::227[User Manual] and the xref::152[Asciidoc Guide] for info on writing documents in Manuscripta.io.\n\n"
    default_text << "== Examples\n\nimage::61[]\n\n*Groceries*\n\n. Bread\n. Milk\n. Cereal\n\n"
    default_text << "The http://nytimes.com[New York Times] has excellent crossword puzzles."

    document.text = @params[:text] || default_text
    document.kind = author.get_preference('doc_format') || 'asciidoc'
    if document.kind == 'text'
      document.rendered_text = document.text
    else
      document.rendered_text = Asciidoctor.convert(document.text)
    end

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
        @parent_document.move_last_subdocument(target_index)
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




