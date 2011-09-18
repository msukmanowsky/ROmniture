require 'rubygems'
require 'test/unit'
require 'yaml'

require 'romniture'

class ClientTest < Test::Unit::TestCase
  
  def setup
    config = YAML::load(File.open("test/config.yml"))
    @config = config["omniture"]
    
    @client = ROmniture::Client.new({
      :username => "#{@config["username"]}",
      :shared_secret => "#{@config["shared_secret"]}",
      :environment => "#{@config["environment"]}",
      :wait_time => @config["wait_time"]
    })
  end
  
  def test_simple_request
    response = @client.request('Company.GetReportSuites')
    
    assert_instance_of Hash, response, "Returned object is not a hash."
    assert(response.has_key?("report_suites"), "Returned hash does not contain any report suites.")
  end
  
  def test_report_request
    response = @client.get_report "Report.QueueOvertime", {
      "reportDescription" => {
        "reportSuiteID" => "#{@config["report_suite_id"]}",
        "dateFrom" => "2011-01-01",
        "dateTo" => "2011-01-10",
        "metrics" => [{"id" => "pageviews"}]
        }
      }
    
    assert_instance_of Hash, response, "Returned object is not a hash."
    assert(response["report"].has_key?("data"), "Returned hash has no data!")
  end
  
end