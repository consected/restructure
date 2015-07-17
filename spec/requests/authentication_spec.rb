require 'rails_helper'

describe "user and admin authentication" do
  before(:each) do
    
    @url_list = Rails.application.routes.routes.map {|r|       
      url = r.path.spec.to_s
      method = nil
      rm = r.constraints[:request_method].to_s 
      
      case rm
      when '(?-mix:^POST$)'
        method = :post
      when '(?-mix:^GET$)'
        method = :get
      when '(?-mix:^PATCH$)'
        method = :patch
      when '(?-mix:^PUT$)'
        method = :put
      when '(?-mix:^DELETE$)'
        method = :delete
      when nil || ''
        method = :get
      else
        raise "Unrecognized method (#{rm}) for #{url}"
      end
      
      rcont = r.defaults[:controller]
      res = url.gsub('(.:format)','').gsub(/:.+?\//,"#{rand(100000)}/").gsub(/:.+?$/,"#{rand(100000)}")      
      puts "method #{method} / #{r.defaults[:controller]}: #{res}"
      {url: res, method: method, controller: rcont }
    }
    
  end

  it "redirects to user login page for all paths when not logged in" do
    
    skip_urls = ["/admins/sign_in", "/users/sign_in"]
    
    @url_list.each do |url|
      if url[:controller] && !skip_urls.include?(url[:url])
        puts "attempting URL: #{url}"
        case url[:method] 
        when :get
          get url[:url] 
        when :patch
          patch url[:url] 
        when :put
          put url[:url]
        when :delete
          delete url[:url]
        when :post
          post url[:url]

        end
        expect(response).to have_http_status(302), "expected a redirect for #{url}. Got #{response.status}"
        #expect(response).to redirect_to('/users/sign_in') # redirect_to('/admins/sign_in')#, "expected a redirect for #{url}. Got #{response.inspect}"
      else
        puts "Skipping url #{url[:url]} (#{url[:method]}) - no controller or url skipped"
      end
    end
    
  end
end

