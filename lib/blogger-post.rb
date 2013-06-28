class BloggerPost

  attr_accessor :content, :title

  def initialize(title, content)
    @title = title
    @content = content
  end

  def to_chapter
    chapter = Chapter.new(@content.split("\n"))
    chapter.content = @content
    chapter.file_name = @title.slug
    chapter.meta['subhead'] = @title

    chapter
  end

end
