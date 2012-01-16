def new_project
  project = Relapse::Project.new
  project.name = "Test App"
  project.version = "0.1"
  project.files = source_files

  project
end