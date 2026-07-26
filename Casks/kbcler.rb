cask "kbcler" do
  version "1.1.0"
  sha256 "f0df80530aa449cbf7a8896f3f6c3a84806d2bb05e1dae6bc64026fc33587601"

  url "https://github.com/enesyaks/KeyboardCleaner/releases/download/v#{version}/KeyboardCleaner-#{version}.zip"
  name "KeyboardCleaner"
  desc "Lock your keyboard while you clean it"
  homepage "https://github.com/enesyaks/KeyboardCleaner"

  depends_on macos: :sonoma

  app "KeyboardCleaner.app"

  # The app is ad-hoc signed (not notarized by Apple), so Gatekeeper would
  # otherwise block it with a "cannot verify it is free of malware" prompt.
  # Strip the quarantine flag on install so the app opens normally.
  postflight do
    system_command "/usr/bin/xattr",
                   args: ["-dr", "com.apple.quarantine", "#{appdir}/KeyboardCleaner.app"],
                   sudo: false
  end

  zap trash: "~/Library/Preferences/com.enes.KeyboardCleaner.plist"

  caveats <<~CAVEATS
    KeyboardCleaner is open-source and ad-hoc signed (not notarized by Apple).
    If macOS still blocks it on first launch, remove the quarantine flag manually:

      xattr -dr com.apple.quarantine "#{appdir}/KeyboardCleaner.app"

    Or reinstall without quarantine:

      brew reinstall --cask --no-quarantine kbcler
  CAVEATS
end
