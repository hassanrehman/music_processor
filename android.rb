class Android

  ADB = "/home/sagii/apps/android/adt-bundle-linux-x86_64/sdk/platform-tools/adb"
  A_PATH = "/sdcard/Samsung/Music"

  def self.cp(full_path)
  	#assuming the format /some/long/full/path/artist/album/song.mp3

  	t = full_path.split("/")
  	dest_path = "#{t[-3]} -- #{t[-2]} - #{t[-1]}"

    cmd = "#{ADB} push \"#{full_path}\" \"#{A_PATH}/#{dest_path}\""
    puts cmd
    `#{cmd}`
  end
end