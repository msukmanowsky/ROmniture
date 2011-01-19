require 'rubygems'

require 'httpi'
require 'digest/md5'
require 'digest/sha1'
require 'base64'
require 'json'

module ROmniture
  
  class Client
    
    BASE_URI = 'https://api2.omniture.com/admin/1.2/rest/'
    
    def initialize(options={})
      @username       = options[:username]
      @shared_secret  = options[:shared_secret]
      
      HTTPI.log = false
    end
    
    def invoke_simple(method)
      response = send_request(method, {})
      
      JSON.parse response.body
    end
    
    def invoke_report(method, report_description)      
      response = send_request(method, report_description)
      
      if response.code == 200
        json = JSON.parse response.body
        if json["status"] == "queued"
          puts "Report with ID (" + json["reportID"].to_s + ") queued.  Now fetching report..."
          return get_queued_report json["reportID"]
        else
          # Not queued error
        end
      else
        # Couldn't even do a request
      end
      
      
    end
    
    private
    
    def send_request(method, data)
      generate_nonce
      
      request = HTTPI::Request.new
      request.url = BASE_URI + "?method=#{method}"
      request.headers = request_headers
      request.body = data.to_json

      HTTPI.post request
    end
    
    def generate_nonce
      @nonce          = Digest::MD5.new.hexdigest(rand().to_s)
      @created        = Time.now.strftime("%Y-%m-%dT%H:%M:%SZ")
      combined_string = @nonce + @created + @shared_secret
      sha1_string     = Digest::SHA1.new.hexdigest(combined_string)
      @password       = Base64.encode64(sha1_string).to_s.chomp("\n")
    end    

    def request_headers 
      {
        "X-WSSE" => "UsernameToken Username=\"#{@username}\", PasswordDigest=\"#{@password}\", Nonce=\"#{@nonce}\", Created=\"#{@created}\""
      }
    end
    
    def get_queued_report(report_id)
      done = false
      error = false

      begin
        sleep 5
        
        response = send_request("Report.GetStatus", {"reportID" => "#{report_id}"})
        #puts "Checking on report #{report_id} status..."
        
        if response.code == 200
          json = JSON.parse response.body
          #puts "Report #{report_id}'s status is: " + json["status"].to_s
          if json["status"] == "done"
            done = true
          elsif json["status"] == "failed"
            error = true
          end
        else
          done = true
          error = true
        end
      end while !done && !error
      
      if error
        raise 'An error has occured'
      end
      
      response = send_request("Report.GetReport", {"reportID" => "#{report_id}"})
      JSON.parse response.body
    end
  end

end