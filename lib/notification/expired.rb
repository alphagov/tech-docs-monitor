require 'date'

module Notification
  class Expired
    def include?(page)
      page.review_by <= Date.today
    end

    def line_for(page)
      age = (Date.today - page.review_by).to_i
      expired_when = if page.review_by == Date.today
                       "today"
                     elsif age == 1
                       "yesterday"
                     else
                       "#{age} days ago"
                     end
      "- <#{page.url}|#{page.title}> (#{expired_when})"
    end

    def singular_message
        "I've found a page that is due for review"
    end

    def multiple_message
        "I've found %s pages that are due for review"
    end
  end
end
