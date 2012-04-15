require 'sinatra'
require "rest-client"
require "json"

set :public_folder, File.dirname(__FILE__)

get '/' do
  return File.open('index.html')
end

post '/drink' do

end

get '/callback' do
  if !params[:error]
    # Sends a POST request to https://mhealth.att.com/access_token.json,
    # providing the Client ID and Secret Key as HTTP Basic Authorization
    # credentials, and a post body containing grant_type=authorization_code,
    # code=the Authorization Code from mHealth Connect, and
    # redirect_uri=the same redirect URI given in the mHealth Connect link.
    response = RestClient.post("https://healthydrinker:qaS3HnaJYbgCxNegzkfXSCa9o1l8pFQNtJORuMJ@mhealth.att.com/access_token.json", {
      :grant_type => "authorization_code",
      :code => params[:code],
      :redirect_uri => SlumberScore.setting(:redirect_uri)
    })

    # Parses the JSON response from the server (which contains the Access
    # Token) using the Ruby JSON library, and stores the Access Token in a
    # session cookie.
    #
    # The JSON response from the server looks like:
    # {"access_token":"1bf71826-a05a-4fd3-9840-e05f8EXAMPLE"}
    session[:access_token] = JSON.parse(response)["access_token"]
  end

  # With the Access Token on a session cookie, redirects the User to the
  # application root, re-rendering the mobile application. As a client-side
  # application it will read the Access Token from the session cookie and use
  # it to make requests to the mHealth API.
  redirect "/#selection"
end
