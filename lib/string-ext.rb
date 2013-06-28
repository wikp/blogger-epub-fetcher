class String

  def strip_html
    self.gsub(/<br ?\/?>/, "\n").gsub(/<p[^>]*>/, "\n").gsub(/<\/?[^>]*>/, '')
  end

  def slug
    self.gsub(/[^a-zęóąśłżźćńA-ZĘÓĄŚŁŻŹĆŃ0-9]+/, '_')
  end

end
