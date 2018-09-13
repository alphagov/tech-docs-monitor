require 'date'

module Notification
  class WillExpireBy
    def initialize(expiry_date)
      @expiry_date = expiry_date
    end

    def include?(page)
      page.review_by > Date.today && page.review_by <= @expiry_date
    end

    def line_for(page)
      age = (page.review_by - Date.today).to_i
      expires_when = if page.review_by == Date.today
                       "today"
                     elsif age == 1
                       "tomorrow"
                     else
                       "in #{age} days"
                     end
      "- <#{page.url}|#{page.title}> (#{expires_when})"
    end

    def singular_message
        "I've found a page that will expire on or before #{@expiry_date}"
    end

    def multiple_message
        "I've found %s pages that will expire on or before #{@expiry_date}"
    end
  end
end
