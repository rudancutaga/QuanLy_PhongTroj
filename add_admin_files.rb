require 'xcodeproj'

project_path = 'QuanLy_PhongTroj.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

main_group = project.main_group.find_subpath('QuanLy_PhongTroj', false)
controllers_group = main_group.find_subpath('Controllers', true)
controllers_group.set_source_tree('<group>')

['AdminDashboardVC.swift', 'AdminPhongVC.swift', 'AdminUserVC.swift', 'AdminCaiDatVC.swift'].each do |file|
  file_ref = controllers_group.new_reference(file)
  target.source_build_phase.add_file_reference(file_ref)
end

project.save
puts "Successfully added 4 Admin controllers to Xcode project!"
