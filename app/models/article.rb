require 'pg'
require 'uri'
require 'net/http'

class Article
  attr_reader :title, :url, :description, :errors

  def initialize(input = {})
    @title = input['title']
    @url = input['url']
    @description = input['description']
    @errors = []
  end

  def db_connection
    begin
      connection = PG.connect(dbname: "news_aggregator_test")
      yield(connection)
      ensure
      connection.close
    end
  end

  def self.all
    @articles = []
    @result = db_connection { |conn| conn.exec("SELECT * FROM articles") }
    @result.each do |res|
      @articles << Article.new(res)
    end
    @articles
  end

  def existence_checker
    @url_list = []
    result = db_connection {|conn| conn.exec("SELECT * FROM articles")}
    result.each do |res|
      @url_list << res['url']
    end
    @url_list.include? @url
  end

  def url_validator
    @url =~ URI::regexp
  end

  def valid?
    # existence_checker
    if @title == '' || @url == '' || @description == ''
      @errors <<  "Please completely fill out form"
      return false
    end
    if url_validator != 0
      @errors << "Invalid URL"
      return false
    end
    if existence_checker
      @errors << "Article with same url already submitted"
      return false
    end
    if @description.length < 20
      @errors << "Description must be at least 20 characters long"
      return false
    end
    return true
  end
end

# def db_connection
#   begin
#     connection = PG.connect(dbname: "news_aggregator_development")
#     yield(connection)
#     ensure
#     connection.close
#   end
# end
# result = db_connection {|conn| conn.exec("SELECT * FROM articles")}
# result.each do |res|
#   puts res['url']
# end
