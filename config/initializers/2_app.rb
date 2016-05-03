module Gitlab
  def self.config
    Settings
  end

  VERSION = File.read(Rails.root.join("VERSION")).strip
  REVISION = "sandstorm-app" #Gitlab::Popen.popen(%W(git log --pretty=format:%h -n 1)).first.chomp
end
