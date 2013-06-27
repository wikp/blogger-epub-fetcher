require 'google/api_client'
require 'faraday'
require 'epubbery'
require 'rubygems'

class Post
  attr_accessor :content, :title
  def initialize(title, content)
    @title = title
    @content = content
  end
end

unless File.exists? './config.yml'
  raise RuntimeError, 'No config.yml found here'
end

@config = YAML::load(File.read('./config.yml'))

unless @config['api_issuer']
  raise RuntimeError, 'API issuer must be provided in config'
end

@epubbery_location = Gem.loaded_specs['epubbery'].full_gem_path
@api_key_path = @config['api_key_path'] || 'client.p12'
@file_name = @config['target_file_name'] || 'blogger.epub'
@template_path = @config['template_dir'] || @epubbery_location
@destination_dir = @config['destination_dir'] || 'epub'
@api_issuer = @config['api_issuer']
@blog_url = ARGV[0]

@options = {
  :application_name => 'blogger-epub-fetcher',
  :application_version => '1.0'
}

@client = Google::APIClient.new(@options)
@blogger = @client.discovered_api('blogger', 'v3')
@key = Google::APIClient::PKCS12.load_key(@api_key_path, 'notasecret')

@client.authorization = Signet::OAuth2::Client.new(
  :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
  :audience => 'https://accounts.google.com/o/oauth2/token',
  :scope => 'https://www.googleapis.com/auth/blogger',
  :issuer => @api_issuer,
  :signing_key => @key)

@client.authorization.fetch_access_token!

blog = @client.execute(
    :api_method => @blogger.blogs.get_by_url,
    :parameters => {
        :url => @blog_url
    }
)

puts "Retrieving blog of id #{blog.data.id}"

result = @client.execute(
  :api_method => @blogger.posts.list,
  :parameters => {
    :blogId => blog.data.id
  }
)

@post_list = []
@page = 0

while result.data && !result.data.items.empty? do
  result.data.items.each do |retrieved_post|
    post = Post.new(retrieved_post.title, retrieved_post.content.gsub(/<br ?\/?>/, "\n").gsub(/<p[^>]*>/, "\n").gsub(/<\/?[^>]*>/, ""))
    @post_list << post
  end
  result = result.next_page.send(Faraday.default_connection)
  puts "Retrieve page #{@page += 1}"
end

@book = Book.new(@config['book_title'], @config['book_author'] || 'blogger-epub-fetcher')
@book.chapters = []

@post_list.reverse_each do |post|
  @chapter = Chapter.new(post.content.split("\n"))
  @chapter.content = post.content
  @chapter.file_name = post.title.gsub(/[^a-zęóąśłżźćńA-ZĘÓĄŚŁŻŹĆŃ0-9]+/, '_')
  @chapter.meta['subhead'] = post.title

  @book.chapters << @chapter
end

@epub = Epub.new
@epub.make_skeleton(@template_path, @destination_dir)
@epub.write_templates(@book)

system "cd #{@destination_dir} && zip -0Xq #{@file_name} mimetype"
system "cd #{@destination_dir} && zip -Xr9Dq #{@file_name} *"