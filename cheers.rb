require 'sinatra'

set :public_folder, File.dirname(__FILE__)

get '/' do
  return File.open('index.html')
end
