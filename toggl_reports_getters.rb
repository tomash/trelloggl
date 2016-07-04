module TogglReports
  class API


    def get_weekly_report(params)
      get "weekly", params
    end

    def get_details_report(params)
      get "details", params
    end

    def get_summary_report(params)
      get "summary", params
    end
  end
end
