require File.expand_path("../../../teststrap", File.dirname(__FILE__))

def new_project
  project = Releasy::Project.new
  project.name = "Test App"
  project.version = "0.1"
  project.files = source_files
  project.exposed_files = %w[README.txt LICENSE.txt]
  project.add_link "http://spooner.github.com/libraries/releasy/", "Releasy website"
  project.output_path = output_path

  project.add_build :source

  project.add_package :"7z"

  project
end

def archive_file; "test_app_0_1_SOURCE.7z"; end