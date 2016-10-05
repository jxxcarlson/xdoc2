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


  def rewrite_media_urls_for_export

    system("mkdir -p outgoing/#{@document.id}/images")

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
          download_file_name = iii.file
          download_path = "outgoing/#{@document.id}/images/#{download_file_name}"
          new_tag = "#{media_type}::images/#{download_file_name}[#{attributes}]"
          AWS.download('psurl', iii.s3_key, download_path)
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


    renderer = RenderAsciidoc.new(source_text: header + texmacros + document.compile, options: options )
    renderer.rewrite_media_urls_for_export
    file_name = normalize document.title
    system("mkdir -p outgoing/#{document.id}")
    system("mkdir -p outgoing/#{document.id}/images")
    path = "outgoing/#{document.id}/#{file_name}.adoc"
    IO.write(path, renderer.source)
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
    export_adoc(@document, {})
    cmd = "asciidoctor-latex -a inject_javascript=no #{adoc_file_path}"
    system(cmd)
    # system("tar -cvf #{folder}.tar #{folder}/")
    system("cd outgoing; tar -cvf ../#{folder}.tar #{@document.id}/; cd ..")
    puts "FILE_NAME: #{@document.id}.tar".red
    puts "TMPFILE: #{folder}.tar".red
    Noteshare::AWS.upload("#{@document.id}.tar", "#{folder}.tar", 'latex')
  end

  def export
    preamble = AWS.get_string("preamble.tex", "strings")
    prefix = preamble
    prefix <<  "\n\n\\title{#{@document.title}}"
    prefix << "\n\n\\begin{document}\n\n"
    prefix << "\n\n\\maketitle"
    prefix << "\n\n\\tableofcontents"
    prefix << "\n\n"
   suffix = "\n\n\\end{document}n\n"

    @source = prefix + @source + suffix
    renderer = ::RenderAsciidoc.new(source_text: @source).call
    latex_text = renderer.rendered_text

    file_name = normalize @document.title
    system("mkdir -p outgoing/#{@document.id}")

    path = "outgoing/#{@document.id}/#{file_name}.tex"
    IO.write(path, latex_text)

    path = "outgoing/#{@document.id}/#{file_name}.adoc"
    IO.write(path, @document.text)
  end

  def call
    rewrite_media_urls_for_export
    export
  end


end