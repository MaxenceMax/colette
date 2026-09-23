#!/usr/bin/env ruby
# Ajoute les sources Swift de ios/Runner/Documents à la cible Runner (idempotent).
require 'xcodeproj'

project_path = File.expand_path('../Runner.xcodeproj', __dir__)
project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Runner' }
raise 'cible Runner introuvable' if target.nil?

runner_group = project.main_group['Runner']
raise 'groupe Runner introuvable' if runner_group.nil?

group = runner_group['Documents'] || runner_group.new_group('Documents', 'Documents')

Dir[File.expand_path('../Runner/Documents/*.swift', __dir__)].sort.each do |file|
  name = File.basename(file)
  next if target.source_build_phase.files_references.any? { |r| r.path == name }
  ref = group.files.find { |f| f.path == name } || group.new_file(name)
  target.add_file_references([ref])
  puts "ajouté : #{name}"
end

project.save
