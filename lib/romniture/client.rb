module ROmniture
  
  class Client

    DEFAULT_REPORT_WAIT_TIME = 0.25
    
    ENVIRONMENTS = {
      :san_jose       => "https://api5.omniture.com/admin/1.3/rest/",
      :dallas         => "https://api2.omniture.com/admin/1.3/rest/",
      :london         => "https://api3.omniture.com/admin/1.3/rest/",
      :san_jose_beta  => "https://beta-api.omniture.com/admin/1.3/rest/",
      :dallas_beta    => "https://beta-api2.omniture.com/admin/1.3/rest/",
      :sandbox        => "https://api-sbx1.omniture.com/admin/1.3/rest/"
    }    
    
    def initialize(username, shared_secret, environment, options={})
      @username       = username
      @shared_secret  = shared_secret
      @environment    = environment.is_a?(Symbol) ? ENVIRONMENTS[environment] : environment.to_s

      @wait_time      = options[:wait_time] ? options[:wait_time] : DEFAULT_REPORT_WAIT_TIME
      @log            = options[:log] ? options[:log] : false
      @verify_mode    = options[:verify_mode] ? options[:verify_mode] : false
      HTTPI.log       = true
    end
        
    def request(method, parameters = {})
      response = send_request(method, parameters)

      begin
        JSON.parse(response.body)
      rescue JSON::ParserError => pe
        response.body
      rescue Exception => e
        log(Logger::ERROR, "Error in request response:\n#{response.body}")
        raise "Error in request response:\n#{response.body}"
      end
    end
    
    def get_report(method, report_description)      
      response = send_request(method, report_description)
      
      json = JSON.parse response.body
      if json["status"] == "queued"
        log(Logger::INFO, "Report with ID (" + json["reportID"].to_s + ") queued.  Now fetching report...")
        return get_queued_report json["reportID"]
      else
        log(Logger::ERROR, "Could not queue report.  Omniture returned with error:\n#{response.body}")
        raise "Could not queue report.  Omniture returned with error:\n#{response.body}"
      end
    end
    
    attr_writer :log
    
    def log?
      @log != false
    end
    
    def logger
      @logger ||= ::Logger.new(STDOUT)
    end
    
    def log_level
      @log_level ||= ::Logger::INFO
    end
    
    def log(*args)
      level = args.first.is_a?(Numeric) || args.first.is_a?(Symbol) ? args.shift : log_level
      logger.log(level, args.join(" ")) if log?
    end

    # For Trended or Overtime reports, the response from Omniture's API is often deeply nested and difficult to traverse.
    # This function basically denormalizes/flattens the hierarchical structure into a simple array of hashes.
    # So for example, if the top level element is browser, and the second level is page, and the third level is datetime, 
    #   this function produces an array of hashes that each have a "browser", "page", and "datetime" keys along with a 
    #   key for each metric.
    def flatten_response(resp)
      @flattened = []
      report = resp["report"]
      elements = report["elements"].map{|e| e["id"]}
      metrics = report["metrics"].map{|e| e["id"]}

      #For some reason OMTR doesn't list the datetime in the elements list if it is the top-level element, so add it in.
      datetime_index = elements.index{|e| e == "datetime"}
      elements.unshift("datetime") if datetime_index.nil?
      
      flatten_report(report['data'], elements, metrics) 
      @flattened
    end
        
    private
    def flatten_report( data, elements, metrics, current_level = 1, result_row = nil)
      data.each do |current_node|
        if current_level == 1 then result_row = Hash.new else result_row = result_row.clone end
       
        #Get the element at this level and store it in our result row, so this will end up with something like
        # { "browser" => "Google Chrome 25.0" } or { "datetime" => "Fri. 1 Mar. 2013" }
        element_name = elements[current_level-1]
        result_row[element_name] = current_node["name"]

        #If there are still more breakdown levels to work our way down, continue recursively working down them.
        #If not, then we are at the bottom level, so take our result row and save it in the @flattened array.
        if current_node.has_key?("breakdown")
          flatten_report( current_node["breakdown"], elements, metrics, current_level + 1, result_row)
        else
          metrics.each_with_index { |metric, i| result_row[metric] = current_node['counts'][i].to_i }
          @flattened <<  result_row
        end

      end
    end



    
    def send_request(method, data)
      log(Logger::INFO, "Requesting #{method}...")
      generate_nonce
      
      log(Logger::INFO, "Created new nonce: #{@password}")
      
      request = HTTPI::Request.new

      if @verify_mode
        request.auth.ssl.verify_mode = @verify_mode
      end

      request.url = @environment + "?method=#{method}"
      request.headers = request_headers
      request.body = data.to_json

      response = HTTPI.post(request)
      
      if response.code >= 400
        log(:error, "Request failed and returned with response code: #{response.code}\n\n#{response.body}")
        raise "Request failed and returned with response code: #{response.code}\n\n#{response.body}" 
      end
      
      log(Logger::INFO, "Server responded with response code #{response.code}.")
      
      response
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
        "X-WSSE" => "UsernameToken Username=\"#{@username}\", PasswordDigest=\"#{@password}\", Nonce=\"#{@nonce}\", Created=\"#{@created}\"",
        'Content-Type' => 'application/json'   #Added by ROB on 2013-08-22 because the Adobe Social API seems to require this be set
      }
    end
    
    def get_queued_report(report_id)
      done = false
      error = false
      status = nil
      start_time = Time.now
      end_time = nil

      begin
        response = send_request("Report.GetStatus", {"reportID" => "#{report_id}"})
        log(Logger::INFO, "Checking on status of report #{report_id}...")
        
        json = JSON.parse(response.body)
        status = json["status"]
        
        if status == "done"
          done = true
        elsif status == "failed"
          error = true
        end
        
        sleep @wait_time if !done && !error
      end while !done && !error
      
      if error
        msg = "Unable to get data for report #{report_id}.  Status: #{status}.  Error Code: #{json["error_code"]}.  #{json["error_msg"]}."
        log(:error, msg)
        raise ROmniture::Exceptions::OmnitureReportException.new(json), msg
      end
            
      response = send_request("Report.GetReport", {"reportID" => "#{report_id}"})

      end_time = Time.now
      log(Logger::INFO, "Report with ID #{report_id} has finished processing in #{((end_time - start_time)*1000).to_i} ms")
      
      JSON.parse(response.body)
    end
  end
end
