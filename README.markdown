# romniture
To be pronounced...RAWWWRROMNITURE

## what is it
romniture is a minimal Ruby wrapper to [Omniture's REST API](http://developer.omniture.com).  It follows a design policy similar to that of [sucker](https://rubygems.org/gems/sucker) built for Amazon's API.

Omniture's API is closed, you have to be a paying customer in order to access the data.

## installation
    [sudo] gem install romniture

## initialization and authentication
romniture requires you supply the `username`, `shared_secret` and `environment` which you can access within the Company > Web Services section of the Admin Console.  The environment you'll use to connect to Omniture's API depends on which data center they're using to store your traffic data and will be one of:

* San Jose (https://api.omniture.com/admin/1.3/rest/)
* Dallas (https://api2.omniture.com/admin/1.3/rest/)
* London (https://api3.omniture.com/admin/1.3/rest/)
* San Jose Beta (https://beta-api.omniture.com/admin/1.3/rest/)
* Dallas (beta) (https://beta-api2.omniture.com/admin/1.3/rest/)
* Sandbox (https://api-sbx1.omniture.com/admin/1.3/rest/)

Here's an example of initializing with a few configuration options.

    client = ROmniture::Client.new(
      username, 
      shared_secret, 
      :san_jose, 
      :verify_mode	=> nil	# Optionaly change the ssl verify mode.
      :log => false,    		# Optionally turn off logging if it ticks you off
      :wait_time => 1   		# Amount of seconds to wait in between pinging 
                        		# Omniture's servers to see if a report is done processing (BEWARE OF TOKENS!)
      )
    
## usage
There are only two core methods for the client which doesn't try to "over architect a spaghetti API":

* `get_report` - used to...while get reports and
* `request` - more generic used to make any kind of request

For reference, I'd recommend keeping [Omniture's Developer Portal](http://developer.omniture.com) open as you code .  It's not the easiest to navigate but most of what you need is there.

The response returned by either of these requests Ruby (parsed JSON).

## examples
    # Find all the company report suites
    client.request('Company.GetReportSuites')
    
    # Get an overtime report
    client.get_report "Report.QueueOvertime", {
      "reportDescription" => {
        "reportSuiteID" => "#{@config["report_suite_id"]}",
        "dateFrom" => "2011-01-01",
        "dateTo" => "2011-01-10",
        "metrics" => [{"id" => "pageviews"}]
        }
      }

## see also
My other client library [comscore_ruby](https://github.com/msukmanowsky/comscore_ruby) for those of you looking to pull data from comscore as well.