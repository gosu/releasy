def win32_project
  project = Relapse::Project.new
  project.name = "Test App"
  project.version = "0.1"
  project.files = source_files
  project.ocra_parameters = "--no-enc"
  project.readme = "README.txt"
  project.add_link "http://www.website.com", "Website"

  project
end

def link_file
  "[InternetShortcut]\nURL=http://www.website.com\n"
end