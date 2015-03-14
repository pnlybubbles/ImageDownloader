# encoding: utf-8

require "sinatra"
require "cgi"
require "nokogiri"
require "open-uri"
require "json"

class GetImageLinks
  def initialize(out)
    @out = out
  end

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
    p = Progress.new(doc.css("div.gdtm").length, "画像のURLを解析中...", @out)
    doc.css("div.gdtm").each { |n|
      target_url = n.css("a")[0]["href"]
      target_doc = Nokogiri::HTML(open(target_url))
      imgs_url << target_doc.css("#img")[0]["src"]
      p.step
    }
    return imgs_url, doc.title
  end
end

class Progress
  def initialize(length, title, out)
    @count = 0
    @length = length
    @title = title
    @out = out
    @out << "event:progress_initialize\n"
    @out << "data:#{title}\n\n"
  end
 
  def step
    if @count < @length
      @count += 1
      @out << "event:progress_set\n"
      @out << "data:#{Rational(@count, @length).to_f}\n\n"
    end    
  end
end

class Worker < Sinatra::Base
  get "/analize" do
    headers "Content-Type" => "text/event-stream"
    stream do |out|
      begin
        scraping = GetImageLinks.new(out)
        url = CGI.unescape(params[:url])
        puts url
        puts "analizing image links..."
        case url
        when /http:\/\/g\.e-hentai\.org\//
          imgs_url, title = scraping.get_hentai_img_links(url)
        else
          imgs_url, title = scraping.get_img_links(url)
        end

        out << "event:title\n"
        out << "data:#{title}\n\n"

        if imgs_url.empty?
          puts "no images available"
          out << "event:fail\n"
          out << "data:no images available\n\n"
          out << "event:close\n"
          out << "data:none\n\n"
        else
          puts "#{imgs_url.length} images found"
          out << "event:result\n"
          out << "data:#{JSON.generate(imgs_url)}\n\n"

          out << "event:close\n"
          out << "data:none\n\n"
        end
      rescue Exception => e
        out << "event:fail\n"
        out << "data:#{e}\n\n"
        out << "data:#{e.backtrace.join("\n")}\n\n"
        out << "event:close\n"
        out << "data:none\n\n"
      end

      out.close
    end
  end

  get "/geturl" do
    file = open(CGI.unescape(params[:url]))
    content_type file.content_type
    return file.read
  end

  get "/" do
    erb :index
  end
end
