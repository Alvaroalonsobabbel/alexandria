class BooksController < ApplicationController
  def index
    books = eager_load(filter(sort(paginate(Book.all)))).map do |book|
      BookPresenter.new(book, params).fields.embeds
    end

    render json: { data: books }.to_json
  end
end
