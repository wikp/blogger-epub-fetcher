# Blogger EPUB Fetcher

Ruby script that retrieves Blogger content and creates an EPUB where every
single post becomes a book's chapter. Then, with [Calibre][1], you can
send it to your Kindle or other e-book reader. Inspiration of this
script was my desire to read _Paris Spleen_ by Charles Baudelaire.

## Usage

Script is very simple and doesn't allow to perform sophisticated
actions. If you need some more control of EPUB file, you probably need
to write code yourself.

* Install required gems: 'sudo gem install google-api-client epubbery'.
* Visit [Google API Console][2] and ask for access to Blogger API. You
  will need to write to Google with some explanation of what you want to
  do with API. This will probably take day or two.
* Enable OAuth2 access in `API Access` section of the console and get your
  key file.
* Run `cp config.yml config.yml.dist`.
* Change information in `config.yml`.
* Run script with an address of blog you want to download as an argument:
  `ruby blogger-fetcher.rb http://example.blogspot.com`.
