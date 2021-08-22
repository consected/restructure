module CollegesHelper
  def college_array
    res = Classification::College.selector_array.map(&:captionize).uniq!
    res.to_json.html_safe
  end
end
