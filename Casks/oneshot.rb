version_value = File.read(File.expand_path("../VERSION", __dir__)).lines.map(&:strip).find do |line|
  line.match?(/^\d+\.\d+\.\d+$/)
end
raise "VERSION file missing or invalid" unless version_value

cask "oneshot" do
  version version_value
  sha256 "aec5d3b0a9e7f01592647c42dc3bcbd1b9fe22dffc6fb8eebfc82bafeadfb7e5"

  url "https://github.com/grantbirki/oneshot/releases/download/v#{version}/OneShot.zip"
  name "OneShot"
  desc "Open source screenshot utility for macOS"
  homepage "https://github.com/grantbirki/oneshot"

  app "OneShot.app"
end
