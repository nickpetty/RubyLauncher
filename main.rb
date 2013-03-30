Shoes.setup do
  gem 'archive-zip'
	gem 'rubyzip'
end


Shoes.app(title: "RubyLauncher", width: 600, height: 400) do
#per batch file, APPDATA is now APPDATA\.rubylauncher\
@workingDir = ENV['APPDATA'] + '.minecraft'
@username = "nickpetty@kf5jak.com"
@password = "sS129909847"
@sessionid = ""
@user = ""

require 'fileutils'
require 'net/http'
require 'archive/zip'
require 'zip/zipfilesystem'
require 'rexml/document'
require 'open-uri'
require 'zip/zip'

def downloadFile(hostname, webdir, filename, dest)
	if filename =~ / /
		filename.gsub!(' ', '%20')
	end

	url = webdir.to_s + filename.to_s
	puts "Downloading " + filename
	a = "http://" + hostname + webdir + filename
	thread = download(a)
	puts " %.2f%%\r" % thread[:progress].to_f until thread.join 1
	Net::HTTP.start(hostname) do |http|
		resp = http.get(url)
		open(filename, "wb") do |file|
			if file =~ /%20/
				file.gsub!('%20', ' ')
				filename = file
			end
			file.write(resp.body)
		end
	end
	
	FileUtils.mv(filename, dest)
end

def download(url) #https://gist.github.com/Burgestrand/454926
  Thread.new do
    thread = Thread.current
    body = thread[:body] = []
    url = URI.parse url
    Net::HTTP.new(url.host, url.port).request_get(url.path) do |response|
      length = thread[:length] = response['Content-Length'].to_i
 
      response.read_body do |fragment|
        body << fragment
        thread[:done] = (thread[:done] || 0) + fragment.length
        thread[:progress] = thread[:done].quo(length) * 100
      end
    end
  end



end

def downloadFiles(hostname, webdir, filename, dest)
parameters = "http://" + hostname + webdir + filename
thread = download(parameters, dest)
print " %.2f%%" % thread[:progress].to_f until thread.join 1
#FileUtils.mv(filename, dest)
end

def downloadResourcesXML
	
@resources_links = []
url = 'http://s3.amazonaws.com/MinecraftDownload'
xml_data = Net::HTTP.get_response(URI.parse(url)).body
doc = REXML::Document.new(xml_data)
titles = []

	doc.elements.each('ListBucketResult/Contents/Key') do |ele|
   		titles << ele.text
	end

	titles.each do |title|
		if title =~ /resources/
			@resources_links << title
		end
	end

#ary = [0,1,5,9,10,11,25,32,35,40,92,109,138,139,140,157]
ary = [0,0,3,6,6,6,19,25,27,31,82,98,126,126,126,142]
@folders = []

	ary.each do |ind|
		@folders << @resources_links.fetch(ind)
		@resources_links.delete_at(ind)
	end
	
	@folders.each do |folder|
		folder.gsub!('/','\\')
		folder.chop
		aFolder = "\\" + folder
		makesubDir(aFolder)
		#puts "Made SubDir ", aFolder
	end

	@resources_links.each do |resource|
		file = resource.split('/')[-1]
		
		if resource =~ /#{file}/
			resource [file] = ""
			webdir = "/MinecraftDownload/" + resource
			destDir = resource.gsub!('/','\\')
		end
		
		dest = @workingDir + "\\" + destDir 
		downloadFile("s3.amazonaws.com", webdir, file, dest)
		
	end

end


def makeworkingDir
	FileUtils.mkdir_p @workingDir
end

def makesubDir(subDir)
	sub = @workingDir + subDir
	FileUtils.mkdir_p sub
end

def checkInstall
	if File.directory?("#{@workingDir}\\bin") == true
		puts "yes"
	else
		installMinecraft
	end
end

def installMinecraft
	
	#makeworkingDir
	
	#makesubDir("\\bin")
	#downloadFile("assets.minecraft.net", "/1_4_7/", "minecraft.jar", "#{@workingDir}\\bin")
	#downloadFile("s3.amazonaws.com", "/MinecraftDownload/", "jinput.jar", "#{@workingDir}\\bin")
	#downloadFile("s3.amazonaws.com", "/MinecraftDownload/", "lwjgl.jar", "#{@workingDir}\\bin")
	#downloadFile("s3.amazonaws.com", "/MinecraftDownload/", "lwjgl_util.jar", "#{@workingDir}\\bin")

	#makesubDir("\\bin\\natives")
	#downloadFile("s3.amazonaws.com", "/MinecraftDownload/", "windows_natives.jar", "#{@workingDir}\\bin\\natives")
	#File.rename("#{@workingDir}\\bin\\natives\\windows_natives.jar", "#{@workingDir}\\bin\\natives\\windows_natives.zip")
	#zipLocal = @workingDir + "\\bin\\natives\\windows_natives.zip"
	#zipPath = @workingDir + "\\bin\\natives\\"
	#Archive::Zip.extract(zipLocal, zipPath)
	#File.delete("#{@workingDir}\\bin\\natives\\windows_natives.zip")
	#downloadResourcesXML
	#downloadFile("kf5jak.com", "/", "discoverpackruby.zip", "#{@workingDir}\\modpack.zip")
	Archive::Zip.extract("#{@workingDir}\\modpack.zip", "#{@workingDir}")
	#Archive::Zip.extract("#{@workingDir}\\bin\\modpack.zip", "#{@workingDir}")
	installModpack

end

def getSessionID(email, pass)
	
	url = '/?user=', email, '&password=', pass, '&version=13'
	api_return = Net::HTTP.get('login.minecraft.net', url.join.to_s)

	if api_return.length == 9
		puts "Incorrect Username/Password"
		exit
	else
		ary = api_return.split(":")
		var1 = ary[3]
		var2 = ary[4]
		var3 = var1 + ":" + var2
		@sessionid = var3
		@user = ary[2]
	end
end


def startMinecraft
	checkInstall
	#getSessionID("nickpetty@kf5jak.com", "sS129909847")
	var = 'start /wait java -Xms256m -Xmx256m -cp "' + @workingDir + '\bin\minecraft.jar;' + @workingDir + '\bin\jinput.jar;' + @workingDir + '\bin\lwjgl.jar;' + @workingDir + '\bin\lwjgl_util.jar" -Djava.library.path="' + @workingDir + '\bin\natives" net.minecraft.client.Minecraft ' + @user + ' ' + @sessionid
	system(var)
	
end

def installModpack

#FileUtils.cp("#{@workingDir}\\bin\\minecraft.jar", "#{@workingDir}\\bin\\original.jar")

	#Zip::ZipFile.open("#{@workingDir}\\bin\\minecraft.jar") do |zfile|
		#zfile.file.delete("META-INF/MANIFEST.MF")
		#zfile.file.delete("META-INF/MOJANG_C.DSA")
		#zfile.file.delete("META-INF/MOJANG_C.SF")
		#zfile.file.delete("net/minecraft/client/ClientBrandRetriever.class")
		#zfile.file.delete("net/minecraft/client/Minecraft.class")
		#zfile.file.delete("net/minecraft/client/MinecraftApplet.class")
	#end
Archive::Zip.archive("#{@workingDir}\\bin\\minecraft.jar", "#{@workingDir}\\bin\\modpack.zip/.")

end

def checkStoredEmail
	
end

def storeEmail
	configFile = @workingDir + "\\" + "config"
	File.open(yourfile, 'w') { |file| file.write(@username) }
end



#Begin Shoes GUI



stack do 

username_field = edit_line
password_field = edit_line
	button("Launch") do 
		@username = username_field.text
		@password = password_field.text

		getSessionID(@username, @password)
		startMinecraft
	end
	
end
end
