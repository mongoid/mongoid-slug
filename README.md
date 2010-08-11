Mongoid Slug
============

Mongoid Slug generates a URL slug or permalink based on a field or set of fields in a Mongoid model.

Examples
--------

Here's a book that embeds many authors:

    class Book
      include Mongoid::Document
      include Mongoid::Slug
      field :title
      slug  :title
      embeds_many :authors
    end

    class Author
      include Mongoid::Document
      include Mongoid::Slug
      field :first_name
      field :last_name
      slug  :first_name, :last_name
      embedded_in :book, :inverse_of => :authors
    end

The finders in our controllers should look like:

    def find_book
      @book = Book.where(:slug => params[:id]).first
    end

    def find_book_and_author
      @book = Book.where(:slug => params[:book_id]).first
      @author = @book.authors.where(:slug => params[:id]).first
    end

If you are wondering why I did not include a *find_by_slug* helper, [read on](http://groups.google.com/group/mongoid/browse_thread/thread/5905589e108d7cc0?pli=1).

To demo some more functionality in the console:

    >> book = Book.create(:title => "A Thousand Plateaus")
    >> book.to_param
    "a-thousand-plateaus"
    >> book.update_attributes(:title => "Anti Oedipus")
    >> book.to_param
    "anti-oedipus"
    >> Book.where(:slug => 'anti-oedipus').first
    #<Book _id: 4c23b1f7faa4a7479a000009, slug: "anti-oedipus", title: "Anti Oedipus">
    >> author = book.authors.create(:first_name => "Gilles", :last_name => "Deleuze")
    >> author.to_param
    => "gilles-deleuze"
    >> author.update_attributes(:first => "Félix", :last_name => "Guattari")
    >> author.to_param
    => "félix-guattari"
    >> book.authors.where(:slug => 'felix-guattari).first
    => #<Author _id: 4c31e362faa4a7050e000003, slug: "félix-guattari", last_name: "Guattari", first_name: "Félix">

`slug` takes `:as` and `:scoped` as arguments. See models in specs for more examples.
