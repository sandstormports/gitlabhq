module Gitlab
  VERSION = File.read(Rails.root.join("VERSION")).strip
  REVISION = "sandstorm-app" #Gitlab::Popen.popen(%W(git log --pretty=format:%h -n 1)).first.chomp

  def self.config
    Settings
  end
end

#
# Load all libs for threadsafety
#
Dir["#{Rails.root}/lib/**/*.rb"].each { |file| require file }
