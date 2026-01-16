cask "oneshot" do
  version :latest
  sha256 :no_check

  url "https://github.com/grantbirki/oneshot/releases/latest/download/OneShot.zip"
  name "OneShot"
  desc "Open source screenshot utility for macOS"
  homepage "https://github.com/grantbirki/oneshot"

  app "OneShot.app"
end
