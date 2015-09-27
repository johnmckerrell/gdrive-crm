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

    json[:headers] = headers
    json[:raw_post] = request.raw_post

    render :json => json
  end

end
