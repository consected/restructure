current_admin = Admin.active.first

rs = Report.active.where(short_name: nil)

rs.each do |r|
  r.current_admin = current_admin
  r.gen_short_name
  r.save!
end
