class BloggerFetcher

  def initialize(config, blog_url)

    raise RuntimeError, 'API issuer must be provided in config. You can obtain it in Google API Console.' unless config['api_issuer']

    @options = {
        :application_name => 'blogger-epub-fetcher',
        :application_version => '1.0'
    }
    @book_title = config['book_title']
    @book_author = config['book_author'] || 'blogger-epub-fetcher'
    @api_key_path = config['api_key_path'] || 'client.p12'
    @file_name = config['target_file_name'] || 'blogger.epub'
    @template_path = config['template_dir'] || Gem.loaded_specs['epubbery'].full_gem_path
    @destination_dir = config['destination_dir'] || 'epub'
    @api_issuer = config['api_issuer']
    @blog_url = blog_url
    @post_list = []
  end

  def write_epub
    auth()
    get_blog_meta()
    retrieve_posts()
    prepare_book()
    generate_epub()
  end

  private

    def generate_epub
      epub = Epub.new
      epub.make_skeleton(@template_path, @destination_dir)
      epub.write_templates(@book)

      system "cd #{@destination_dir} && zip -0Xq #{@file_name} mimetype"
      system "cd #{@destination_dir} && zip -Xr9Dq #{@file_name} *"
    end

    def prepare_book
      @book = Book.new(@book_title || @blog_title, @book_author)
      @book.chapters = @post_list.reverse_each.collect { |post| post.to_chapter }
    end

    def retrieve_posts
      puts "Retrieving blog_id of id #{@blog_id}"

      result = @client.execute(
          :api_method => @blogger.posts.list,
          :parameters => {
              :blogId => @blog_id
          }
      )

      # @todo use generator below!
      page = 0
      while result.data && !result.data.items.empty? do
        result.data.items.each do |retrieved_post|
          post = BloggerPost.new(retrieved_post.title, retrieved_post.content.strip_html)
          @post_list << post
        end
        result = result.next_page.send(Faraday.default_connection)
        puts "Retrieve page #{page += 1}"
      end
    end

    def get_blog_meta
      blog = @client.execute(
          :api_method => @blogger.blogs.get_by_url,
          :parameters => {
              :url => @blog_url
          }
      )

      @blog_id = blog.data.id
      @blog_title = blog.data.name
    end

    def auth
      @client = Google::APIClient.new(@options)
      @blogger = @client.discovered_api('blogger', 'v3')
      key = Google::APIClient::PKCS12.load_key(@api_key_path, 'notasecret')

      @client.authorization = Signet::OAuth2::Client.new(
          :token_credential_uri => 'https://accounts.google.com/o/oauth2/token',
          :audience => 'https://accounts.google.com/o/oauth2/token',
          :scope => 'https://www.googleapis.com/auth/blogger',
          :issuer => @api_issuer,
          :signing_key => key)

      @client.authorization.fetch_access_token!
    end

end