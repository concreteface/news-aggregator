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
  erb :submit_article
end

post '/articles/new' do
  url_list = []
  result = db_connection {|conn| conn.exec("SELECT * FROM articles")}
  result.each do |res|
    url_list << res['url']
  end
  url = URI.parse(params[:url].split.join)
  if params[:url].empty?
    @missing_url = true
    @title = params[:title]
    @description = params[:description]
    erb :submit_article
  elsif params[:description].length < 20
    @short_description = true
    @title = params[:title]
    @url = params[:url]
    erb :submit_article
  elsif url.is_a?(URI::HTTP) == false
    @invalid_url = true
    @title = params[:title]
    @description = params[:description]
    erb :submit_article
  elsif url_list.include? params[:url]
    @repeat = true
    @title = params[:title]
    @description = params[:description]
    erb :submit_article
  else
    db_connection {|conn| conn.exec_params("INSERT INTO articles (title, url, description) VALUES ($1, $2, $3)", [params[:title], params[:url], params[:description]])}
    redirect '/articles'
  end
end
