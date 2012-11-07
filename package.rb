
Package.define("libpng-1.5.13") do |package|
	package.fetch_from :url => "ftp://ftp.simplesystems.org/pub/libpng/png/src/libpng-1.5.13.tar.gz"
	
	package.build(:all) do |platform, config|
		RExec.env(config.build_environment) do
			Dir.chdir(package.source_path) do
				sh("make", "clean") if File.exist? "Makefile"
				sh("./configure", "--prefix=#{platform.prefix}", "--disable-dependency-tracking", "--enable-shared=no", "--enable-static=yes", *config.configure)
				sh("make install")
			end
		end
	end
end

