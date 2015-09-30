class DebugController < ApplicationController

  skip_before_filter :authenticate_user!

  def echo
    json = {}
    headers = {}
    request.headers.each do |k,v|
      if v.kind_of?(String)
        headers[k] = v
      end
    end

    begin
      user, pass = ActionController::HttpAuthentication::Basic::user_name_and_password(request)
    rescue NoMethodError => e
      user = nil
      pass = nil
    end

    json[:headers] = headers
    json[:raw_post] = request.raw_post
    json[:params] = request.params
    json[:auth] = { user: user, pass: pass }

    render :json => json
  end

end
