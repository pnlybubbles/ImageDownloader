require "nokogiri"
require "open-uri"
require "zip"

def get_img_links(url)
  doc = Nokogiri::HTML(open(url))
 
  imgs_url = []
  doc.css("img").each { |n|
    if n.parent.name == "a" && n.parent["href"] =~ /\.(jpg|jpeg|png|gif)[^\.]*$/
      imgs_url << n.parent["href"]
    end
  }
  return imgs_url, doc.title
end

def get_hentai_img_links(url)
  doc = Nokogiri::HTML(open(url))
  imgs_url = []
  p = Progress.new(doc.css("div.gdtm").length)
  doc.css("div.gdtm").each { |n|
    target_url = n.css("a")[0]["href"]
    target_doc = Nokogiri::HTML(open(target_url))
    imgs_url << target_doc.css("#img")[0]["src"]
    p.step
  }
  return imgs_url, doc.title
end

class Progress
  def initialize(length)
    @terminal_col = `tput cols`.to_i
    @count = 0
    @length = length
  end
 
  def step
    @count += 1
    now_progress = ((@terminal_col - 10) * Rational(@count, @length)).round
    print("[" + ("#" * now_progress) + (" " * (@terminal_col - 10 - now_progress)) + "] " + ("  " + (Rational(@count, @length) * 100).to_f.round(1).to_s)[-5,5] + "%\r")
    if @count == @length
      print "\n"
      initialize(@length)
    end
  end
end

loop {
  begin
    print "url : "
    url = gets.strip
    imgs_url = []
    title = ""

    puts "analizing image links..."

    case url
    when /http:\/\/g\.e-hentai\.org\//
      imgs_url, title = get_hentai_img_links(url)
    else
      imgs_url, title = get_img_links(url)
    end

    # puts imgs_url.join("\n")
     
    if imgs_url.empty?
      puts "no images available"
      redo
    end
 
    puts "#{imgs_url.length} images found"
    puts "downloading images..."
    p = Progress.new(imgs_url.length)
 
    folder_name = (DateTime.now.strftime("%y-%m-%d_%H.%M.%S_") + title).gsub(/\\|\//, "")
    Dir::mkdir(folder_name)

    puts "#{imgs_url.length} images found"
    puts "downloading progress : "
    p = Progress.new(imgs_url.length)
    
    folder_name = (DateTime.now.strftime("%y-%m-%d_%H.%M.%S_") + title).gsub(/\\|\//, "")
    Dir::mkdir(folder_name)
    
    imgs_url.each_with_index { |img_url, i|
      begin
        open("./#{folder_name}/" + "000#{i}"[-3, 3] + img_url[/\.(jpg|jpeg|png|gif)/], 'wb') do |f|
          open(img_url) do |data|
            f.write(data.read)
          end
        end
      rescue Exception => e
        puts "Download ERROR : #{e}"
      end
      p.step
    }

    puts "download succeeded in \"#{folder_name}\""
    puts
  rescue Exception => e
    exit 1 if e.to_s == ""
    puts "ERROR : #{e}"
    puts e.backtrace
  end
}

