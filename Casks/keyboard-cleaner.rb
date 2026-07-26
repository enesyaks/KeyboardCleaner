cask "keyboard-cleaner" do
  version "1.0.0"
  sha256 "d5c6e0aeb7ede7cb0a003a12e9a0c5529ce9d7db8ece7aa0ce8718edd6d25573"

  url "https://github.com/enesyaks/KeyboardCleaner/releases/download/v#{version}/KeyboardCleaner-#{version}.zip"
  name "KeyboardCleaner"
  desc "Lock your Mac keyboard while you clean it"
  homepage "https://github.com/enesyaks/KeyboardCleaner"

  depends_on macos: :sonoma

  app "KeyboardCleaner.app"

  zap trash: [
    "~/Library/Preferences/com.enes.KeyboardCleaner.plist",
  ]
end
