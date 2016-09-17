require 'hanami/interactor'

class LatexExporter

  include Hanami::Interactor

  expose :message, :redirect_path


  def initialize(params)
    id = params[:id]
    @document = DocumentRepository.find id
    @source = @document.text
  end

  def normalize(str)
    str = str.gsub(' ', '_').downcase
    str = str.gsub(/[^a-zA-Z_]/, '')
    str.gsub(/_*_/, '_')
  end

  def download_file(url, filepath)
    # return unless File.file?(filepath)
    File.open(filepath, "wb") do |saved_file|
      # the following "open" is provided by open-uri
      open(url, "rb") do |read_file|
        saved_file.write(read_file.read) if read_file
      end
    end
  end

  def rewrite_media_urls_for_export
    doc_folder = @options[:doc_folder] || 'a2a2a2'

    rxTag = /(image|video|audio)(:+)(.*?)\[(.*)\]/
    scanner = @source.scan(rxTag)
    count = 0

    scanner.each do |scan_item|
      count += 1

      media_type = scan_item[0]
      infix = scan_item[1]
      id = scan_item[2]
      attributes = scan_item[3]

      old_tag = "#{media_type}#{infix}#{id}[#{attributes}]"

      if id =~ /^\d+\d$/
        iii = ImageRepository.find id
        if iii
          download_file_name = iii.file_name.sub('image::', 'image_')
          download_path = "outgoing/#{doc_folder}/images/#{download_file_name}"
          new_tag = "image::images/#{download_file_name}[#{attributes}]"
          download_file(iii.url2, download_path)
          @source = @source.sub(old_tag, new_tag)
        end
      end

    end

  end

  def export_adoc(document, options)
    header = '= ' << document.title << "\n"
    header << document.author << "\n"
    header << ":numbered:" << "\n"
    header << ":toc2:" << "\n\n\n"

    renderer = Render.new(header + texmacros + document.compile, options )
    renderer.rewrite_media_urls_for_export
    file_name = normalize document.title
    system("mkdir -p outgoing/#{document.id}")
    system("mkdir -p outgoing/#{document.id}/images")
    path = "outgoing/#{document.id}/#{file_name}.adoc"
    IO.write(path, renderer.source)
  end

  def call
    if @document
      export_latex
      @message = make_message
    else
      @redirect_path = "/error:#{id}?Document not found" if @document == nil
    end
  end

  def folder
    "outgoing/#{@document.id}"
  end

  def adoc_file_path
    file_name = normalize @document.title
    "#{folder}/#{file_name}.adoc"
  end

  def latex_file_path
    file_name =  normalize @document.title
    "#{folder}/#{file_name}.tex"
  end

  def latex_file_name
    file_name = normalize @document.title
    "#{file_name}.tex"
  end


  def export_latex
    system("mkdir -p outgoing/#{@document.id}/images")
    self.export_adoc
    cmd = "asciidoctor-latex -a inject_javascript=no #{adoc_file_path}"
    system(cmd)
    # system("tar -cvf #{folder}.tar #{folder}/")
    system("cd outgoing; tar -cvf ../#{folder}.tar #{@document.id}/; cd ..")
    puts "FILE_NAME: #{@document.id}.tar".red
    puts "TMPFILE: #{folder}.tar".red
    Noteshare::AWS.upload("#{@document.id}.tar", "#{folder}.tar", 'latex')
  end

  def make_message
    output = "<p style='margin:3em;'> <strong>#{@document.title}</strong> exported as Asciidoc and LaTeX to "
    output << "<a href='http://vschool.s3.amazonaws.com/latex/#{@document.id}.tar'>this link</a> "
    output << "<p style='margin:3em;'> The file to download from the link is #{@document.id}.tar</p>"
    output << "</p>\n\n"
  end

end