cask "keyboard-cleaner" do
  version "1.0.0"
  sha256 "9b9c6634ece80973a9c9be4bbedaee4ef864fe87fc36069c0f6950f6161308cf"

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
