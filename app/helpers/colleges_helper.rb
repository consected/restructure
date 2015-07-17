module CollegesHelper

  def college_array
    res = College.selector_array.map {|c| c.titleize}.uniq!
    res.to_json.html_safe
  end
  
end
