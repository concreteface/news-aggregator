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
    valid = true
    if @title == '' || @url == '' || @description == ''
      @errors <<  "Please completely fill out form"
      valid = false
    end
    if url_validator != 0 && @url != ''
      @errors << "Invalid URL"
      valid = false
    end
    if existence_checker
      @errors << "Article with same url already submitted"
      valid = false
    end
    if @description.length < 20 && @description != ''
      @errors << "Description must be at least 20 characters long"
      valid = false
    end
    return valid
  end

  def save
    if valid?
      db_connection {|conn| conn.exec_params("INSERT INTO articles (title, url, description) VALUES ($1, $2, $3)", [@title, @url, @description])}
      return true
    else return false
    end
  end
end
