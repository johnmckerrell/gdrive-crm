class DebugController < ApplicationController

  skip_before_action :authenticate_user!

  def get_auth_details
    begin
      @user, @pass = ActionController::HttpAuthentication::Basic::user_name_and_password(request)
    rescue NoMethodError 
      @user = nil
      @pass = nil
    end

  end

  def echo_auth
    get_auth_details

    if @user.nil?
      headers['WWW-Authenticate'] = 'Basic realm="Test Auth"'
      head 401
    else
      echo
    end

  end

  def message
    render plain: params[:message]
  end

  def echo
    json = {}
    headers = {}
    request.headers.each do |k,v|
      if v.kind_of?(String)
        headers[k] = v
      end
    end

    json[:headers] = headers
    json[:raw_post] = request.raw_post
    json[:params] = request.params
    json[:auth] = { user: @user, pass: @pass }

    render :json => json
  end

end
