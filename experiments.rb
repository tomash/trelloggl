TOGGL_API_TOKEN = "AAA"
TRELLO_API_PUBLIC_KEY = "BBB"
TRELLO_API_MEMBER_TOKEN = "CCC"

require 'togglv8'
require './toggl_reports'

# BEGIN part that's not necessary if workspace_id and project_ids are known
# they can be found in url for editing project: https://www.toggl.com/app/projects/WORKSPACE_ID/edit/PROJECT_ID

toggl_api    = TogglV8::API.new(TOGGL_API_TOKEN)
user         = toggl_api.me(all=true)
workspaces   = toggl_api.my_workspaces(user)

project = toggl_api.my_projects.detect {|p| p["name"] == "BasilHealth"}
last_time_entries = toggl_api.get_time_entries
# END part that's not necessary

# BEGIN TOGGL REPORTS
# reports curl:
# curl -v -u TOGGL_API_TOKEN:api_token -X GET "https://toggl.com/reports/api/v2/details?workspace_id=412497&project_ids=14703807&since=2016-06-01&until=2016-07-01&user_agent=api_test"

workspace_id = 412497 # Rebased
project_ids = 14703807 # BasilHealth

toggl_reports    = TogglReports::API.new(TOGGL_API_TOKEN)

weekly_report = toggl_reports.get_weekly_report({ "user_agent" => "trellogl", "workspace_id" => 412497})

details_report = toggl_reports.get_details_report({ "user_agent" => "trellogl",  "workspace_id" => 412497,  "project_ids" => "14703807",  "since" => "2016-06-01",  "until" => "2016-07-01"})
# result: array with hashes like:
# {"id"=>407200929, "pid"=>14703807, "tid"=>nil, "uid"=>2297271,
#  "description"=>"BAS-374", "start"=>"2016-07-01T06:58:29+02:00", "end"=>"2016-07-01T12:58:29+02:00",
#  "updated"=>"2016-07-01T19:00:27+02:00", "dur"=>21600000, "user"=>"Katarzyna Frey",
#  "use_stop"=>false, "client"=>"AnalyticsFire", "project"=>"BasilHealth",
#  "project_color"=>"0", "project_hex_color"=>"#4dc3ff", "task"=>nil, "billable"=>0.0, "is_billable"=>true, "cur"=>"EUR", "tags"=>[]}

# END TOGGL REPORTS

# BEGIN TRELLO

# using ruby-trello gem
# nice docs: http://www.rubydoc.info/gems/ruby-trello/

require 'trello'
#Trello.open_public_key_url
#Trello.open_authorization_url key: PUBLIC_KEY

Trello.configure do |config|
  config.developer_public_key = TRELLO_API_PUBLIC_KEY
  config.member_token = TRELLO_API_MEMBER_TOKEN
end

member = Trello::Member.find("tomash")

board_id = "EKPjdADu" # AF_PYTH_BH
board = Trello::Board.find(board_id)

lists = board.lists
sprint7list = board.lists.detect{|list| list.name == "Sprint 7 To Do (dev)"}

cards = sprint7list.cards
card = sprint7list.cards.detect {|card| card.name =~ /BAS\W281/}

card.add_comment "Hello from trelloggl!"

# END TRELLO
