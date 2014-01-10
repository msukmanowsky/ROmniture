require 'test/unit'
require 'yaml'
$:.unshift File.expand_path('../../lib', __FILE__)
require 'romniture'

=begin 
In order to properly run these tests, create a config.yml file
with the following values filled in:

omniture:
  username: "username"
  shared_secret: "shared_secret"
  environment: :san_jose
  verify_mode: :none
  wait_time: 10
  report_suite_id: "report_suite_id"

expected_values:
  march_1_2013_pageviews_for_chrome_25: 500
  march_1_2013_pageviews_for_ie_10: 500
  valid_page_name_to_find: "Home Page"
  march_1_2013_pageviews_for_chrome_25_for_specific_page: 500
  march_1_2013_visits_for_chrome_25: 500
  march_1_2013_total_pageviews: 500
  march_1_2013_total_visits: 500

=end

class ParseResponseTest < Test::Unit::TestCase

  def setup
    config = YAML::load(File.open("test/config.yml"))
    @config = config["omniture"]
    @expected_values = config["expected_values"]

    @client = ROmniture::Client.new(
      @config["username"],
      @config["shared_secret"],
      @config["environment"],
      :verify_mode => @config['verify_mode'],
      :wait_time => @config["wait_time"]
    )

    @request ={
      "reportDescription" => {
        "reportSuiteID" => @config["report_suite_id"],
        "dateFrom" => "2013-03-01",
        "dateTo" => "2013-03-01",
        "dateGranularity" => "day",
        "metrics" => [{"id" => "pageViews"}],
        "elements" => [{"id" => "browser"}]
    }}

  end

  def test_proper_value_parsed_from_basic_one_metric_one_element_trended_report
    resp = @client.get_report "Report.QueueTrended", @request
    flattened = @client.flatten_response(resp)
    assert_equal @expected_values["march_1_2013_pageviews_for_chrome_25"], flattened.find{|e| e['browser'] == "Google Chrome 25.0" and e["datetime"] = "Fri.  1 Mar. 2013"}['pageViews']
  end

  def test_proper_value_parsed_from_single_day_in_trended_report_for_several_days
    @request["reportDescription"]["dateTo"] = "2013-03-04"
    resp = @client.get_report "Report.QueueTrended", @request
    flattened = @client.flatten_response(resp)
    assert_equal @expected_values["march_1_2013_pageviews_for_chrome_25"], flattened.find{|e| e['browser'] == "Google Chrome 25.0" and e["datetime"] = "Fri.  1 Mar. 2013"}['pageViews']
    assert_equal 4, flattened.uniq{|e| e['datetime']}.count
  end

  def test_proper_value_parsed_with_filter_selected_in_element_request
    @request["reportDescription"]["elements"] = [{"id" => "browser", "selected" => ["Microsoft Internet Explorer 10"]}]
    resp = @client.get_report "Report.QueueTrended", @request
    flattened = @client.flatten_response(resp)
    assert_equal @expected_values["march_1_2013_pageviews_for_ie_10"], flattened[0]["pageViews"]
    assert_equal 1, flattened.length
  end

  def test_proper_value_parsed_from_two_element_correlated_trended_report
     @request["reportDescription"]["elements"] = [{"id" => "page"}, {"id" => "browser"}]
     resp = @client.get_report "Report.QueueTrended", @request
     flattened = @client.flatten_response(resp)
     assert_equal @expected_values["march_1_2013_pageviews_for_chrome_25_for_specific_page"], flattened.find{|e| e['browser'] == "Google Chrome 25.0" and e['page'] == @expected_values["valid_page_name_to_find"] and e["datetime"] = "Fri.  1 Mar. 2013"}['pageViews']
  end

  def test_proper_value_parsed_from_two_metric_report
    @request["reportDescription"]["metrics"] << {"id" => "visits"}
    resp = @client.get_report "Report.QueueTrended", @request
    flattened = @client.flatten_response(resp)
    assert_equal @expected_values["march_1_2013_pageviews_for_chrome_25"], flattened.find{|e| e['browser'] == "Google Chrome 25.0" and e["datetime"] = "Fri.  1 Mar. 2013"}['pageViews']
    assert_equal @expected_values["march_1_2013_visits_for_chrome_25"], flattened.find{|e| e['browser'] == "Google Chrome 25.0" and e["datetime"] = "Fri.  1 Mar. 2013"}['visits'] 
  end

  def test_proper_value_parsed_from_no_element_overtime_report
    @request["reportDescription"]["elements"] = []
    resp = @client.get_report "Report.QueueOvertime", @request
    flattened = @client.flatten_response(resp)
    assert_equal @expected_values["march_1_2013_total_pageviews"], flattened[0]["pageViews"]
    assert_equal 1, flattened.length
  end

  def test_proper_value_parsed_from_no_element_two_metric_overtime_report
    @request["reportDescription"]["elements"] = []
    @request["reportDescription"]["metrics"] << {"id" => "visits"}
    resp = @client.get_report "Report.QueueOvertime", @request
    flattened = @client.flatten_response(resp)
    assert_equal @expected_values["march_1_2013_total_pageviews"], flattened[0]["pageViews"]
    assert_equal 1, flattened.length
    assert_equal @expected_values["march_1_2013_total_visits"], flattened[0]["visits"]
  end


end
