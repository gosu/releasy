["bundler", "riot", "rr", "yard"].each do |gem|
  $LOAD_PATH.unshift File.expand_path("../vendor/gems/#{gem}/lib", __FILE__)
end

load 'bin/test_app'