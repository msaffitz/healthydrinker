require 'sinatra'
require "rest-client"
require "json"
require "time"

set :logging, true
set :public_folder, File.dirname(__FILE__)

use Rack::Session::Cookie, :key => "healthydrinker.session"

get '/' do
  return File.open('index.html')
end

post '/drink' do
  response = RestClient.post("https://api-mhealth.att.com/v2/health/source/healthydrinker/data?oauth_token=#{session[:access_token]}",
                              [{"timestamp" => Time.now.strftime('%s'),
                                "name" => "drink",
                                "unit" => "number",
                                "value"=> 1}].to_json)
  logger.info "got response #{response}"
end

get '/getdata' do
  logger.info "token is #{session[:access_token]}"
  drinksR = RestClient.get("https://api-mhealth.att.com/v2/health/source/healthydrinker/data?oauth_token=#{session[:access_token]}")
  changesR = RestClient.get("https://api-mhealth.att.com/v2/health/data?m=gitlogger/changed_lines&oauth_token=#{session[:access_token]}")
  stepsR = RestClient.get("https://api-mhealth.att.com/v2/health/data?m=fitbit/steps&oauth_token=#{session[:access_token]}")

  drinks = JSON.parse(drinksR)
  commits = JSON.parse(changesR)
  steps = JSON.parse(stepsR)

  drinksO = {label: "Drinks", data: {'0' => 0, '1' => 0, '2' => 0, '3' => 0, '4' => 0, '5' => 0, '6' => 0}}
  commitsO = {label: "Changes", data: {'0' => 0, '1' => 0, '2' => 0, '3' => 0, '4' => 0, '5' => 0, '6' => 0}, yaxis: 2}
  stepsO = {label: "Steps", data: {'0' => 0, '1' => 0, '2' => 0, '3' => 0, '4' => 0, '5' => 0, '6' => 0}, yaxis: 3}

  drinks.map { |r|  drinksO[:data][Time.parse( r["timestamp"] ).wday.to_s] += r["value"].to_i }
  commits.map { |r| commitsO[:data][Time.parse( r["timestamp"] ).wday.to_s] +=  r["value"].to_i  }
  steps.map { |r| stepsO[:data][Time.parse( r["timestamp"] ).wday.to_s] +=  r["value"]  }

  drinksO[:data] = drinksO[:data].map { |k,v| [k,v] }
  commitsO[:data] = commitsO[:data].map { |k,v| [k,v] }
  stepsO[:data] = stepsO[:data].map { |k,v| [k,v] }

  content_type :json
  [drinksO, commitsO, stepsO].to_json
end


get '/callback' do
  if !params[:error]
    # Sends a POST request to https://mhealth.att.com/access_token.json,
    # providing the Client ID and Secret Key as HTTP Basic Authorization
    # credentials, and a post body containing grant_type=authorization_code,
    # code=the Authorization Code from mHealth Connect, and
    # redirect_uri=the same redirect URI given in the mHealth Connect link.
    logger.info "callback #{params[:code]}"
    response = RestClient.post("https://healthydrinker:qaS3HnaJYbgCxNegzkfXSCa9o1l8pFQNtJORuMJg@mhealth.att.com/access_token.json", {
      :grant_type => "authorization_code",
      :code => params[:code],
      :redirect_uri => 'http://cheers.herokuapp.com/callback'
    })

    # Parses the JSON response from the server (which contains the Access
    # Token) using the Ruby JSON library, and stores the Access Token in a
    # session cookie.
    #
    # The JSON response from the server looks like:
    # {"access_token":"1bf71826-a05a-4fd3-9840-e05f8EXAMPLE"}
    logger.info "token: #{JSON.parse(response)["access_token"]}"
    session[:access_token] = JSON.parse(response)["access_token"]
  end

  # With the Access Token on a session cookie, redirects the User to the
  # application root, re-rendering the mobile application. As a client-side
  # application it will read the Access Token from the session cookie and use
  # it to make requests to the mHealth API.
  redirect "/#selection"
end
