require 'rubygems'
require 'test/unit'
require 'yaml'

Dir.chdir '../lib'
require 'romniture'

class ClientTest < Test::Unit::TestCase
  
  def setup
    config = YAML::load(File.open("../config.yml"))
    @config = config["omniture"]
    
    @client = ROmniture::Client.new({
      :username => "#{@config["username"]}",
      :shared_secret => "#{@config["shared_secret"]}"
    })
  end
  
  def test_simple_request
    response = @client.invoke_simple 'Company.GetReportSuites'
    
    assert_instance_of Hash, response, "Returned object is not a hash."
    assert(response.has_key?("report_suites"), "Returned hash does not contain any report suites.")
  end
  
  def test_report_request
    response = @client.invoke_report "Report.QueueOvertime", {
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