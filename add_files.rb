require 'xcodeproj'

project_path = 'QuanLy_PhongTroj.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Add Models group and file
main_group = project.main_group.find_subpath('QuanLy_PhongTroj', false)
models_group = main_group.find_subpath('Models', true)
models_group.set_source_tree('<group>')
file_ref_model = models_group.new_reference('PhongTro.swift')
target.source_build_phase.add_file_reference(file_ref_model)

# Add Services group and file 
services_group = main_group.find_subpath('Services', true)
services_group.set_source_tree('<group>')
file_ref_service = services_group.new_reference('RoomService.swift')
target.source_build_phase.add_file_reference(file_ref_service)

project.save
puts "Added PhongTro.swift and RoomService.swift to Xcode project!"
