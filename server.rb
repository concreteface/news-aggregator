require "sinatra"
require "pg"
require_relative "./app/models/article"
require 'pry'

set :views, File.join(File.dirname(__FILE__), "app", "views")

configure :development do
  set :db_config, { dbname: "news_aggregator_development" }
end

configure :test do
  set :db_config, { dbname: "news_aggregator_test" }
end

def db_connection
  begin
    connection = PG.connect(Sinatra::Application.db_config)
    yield(connection)
    ensure
    connection.close
  end
end

get '/' do
  erb :home
end

get '/articles' do
  @articles = db_connection {|conn| conn.exec("SELECT * FROM articles")}
  erb :articles
end

get '/articles/new' do
  @errors = []
  erb :submit_article
end

post '/articles/new' do
  article = Article.new({"title" => params[:title], "url" => params[:url], "description" => params[:description]})
  @title = params[:title]
  @url = params[:url]
  @description = params[:description]
  if article.valid?
    article.save
    redirect '/articles'
  else @errors = article.errors
    erb :submit_article
  end
end
