class Android

  ADB = "/home/sagii/apps/android/adt-bundle-linux-x86_64/sdk/platform-tools/adb"
  A_PATH = "/sdcard/Music"

  def self.cp(full_path, relative_path)
    cmd = "#{ADB} push '#{full_path}' '#{A_PATH}/#{relative_path}'"
    puts cmd
    `#{cmd}`
  end
end