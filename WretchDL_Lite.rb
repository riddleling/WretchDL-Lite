#!/usr/bin/env ruby

#
# Copyright (c) 2012 Wei-Chen Ling.
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#


require 'open-uri'
require 'fileutils'

#
# WretchPhotoURL Class
#
class WretchPhotoURL
  attr_accessor :photo_url
  
  def initialize(photo_url)
    @photo_url = photo_url
  end
  
  def to_file_url
    page_html = open(@photo_url).read
    
    file_url = ""
    page_html.each_line do |line|
      if line =~ /<img id='DisplayImage' src='([^']+)' /
        file_url = Regexp.last_match[1]
      elsif line =~ /<img class='displayimg' src='([^']+)' /
        file_url = Regexp.last_match[1]
      end
    end
    file_url
  end
end


#
# WretchAlbum Class
#
class WretchAlbum
  attr_accessor :id, :number, :name, :pictures, :cover_url
  
  def initialize(id, number, name)
    @id, @number, @name = id, number, name
    @pictures = 0
  end
  
  def photos_urls
    album_url = "http://www.wretch.cc/album/album.php?id=#{@id}&book=#{@number}"
    i = 1
    is_next_page = true
    urls = []
    while is_next_page do
      page_html = open(album_url).read
    
      urls.concat(get_photo_url_list(page_html))
      i += 1
      is_next_page = false
      # Next Page?
      page_html.each_line do |line|
        if line =~ /(album\.php\?id=#{@id}&book=#{@number}&page=#{i})/
          album_url = "http://www.wretch.cc/album/album.php?id=#{@id}&book=#{@number}&page=#{i}"
          is_next_page = true
          break
        end
      end
    end
    urls
  end
  
  private
  def get_photo_url_list(page_html)
    urls = []
    page_html.each_line do |line|
      if line =~ /<a href="\.\/(show.php\?i=#{@id}&b=#{@number}&f=\d+&p=\d+&sp=\d+)".+><img src=/
        photo_url = WretchPhotoURL.new("http://www.wretch.cc/album/#{Regexp.last_match[1]}")
        urls.push(photo_url)
      end
    end
    urls
  end
end


#
# WretchAlbumsInfo Class
#
class WretchAlbumsInfo
  attr_accessor :wretch_id

  def initialize(wretch_id)
    @wretch_id = wretch_id
  end

  def list_of_page(page_number)
    wretch_url = "http://www.wretch.cc/album/#{@wretch_id}"
    if page_number >= 2 
      wretch_url << "&page=#{page_number}"
    end

    page_html = open(wretch_url).read
    albums = []

    page_html.each_line do |line|
      if line =~ /<a href="\.\/album\.php\?id=#{@wretch_id}&book=(\d+)">(.+)<\/a>/
        albums << WretchAlbum.new(@wretch_id, Regexp.last_match[1], Regexp.last_match[2])
      end
      
      if line =~ /(\d+)pictures\s*?<\/font>/
        albums[-1].pictures = Regexp.last_match[1]
      end
    end
    
    covers = {}
    page_html.each_line do |line|
      if line =~ %r!<img src="(http://.+/#{@wretch_id}/(\d+)/thumbs/.+)" border="0" alt="Cover"/>!
        key = $2.to_sym
        covers[key] = $1
      elsif line =~ %r!<img src="(http://.+/#{@wretch_id.downcase}/(\d+)/thumbs/.+)" border="0" alt="Cover"/>!
        key = $2.to_sym
        covers[key] = $1
      end
    end
    
    albums.each do |a|
      key = a.number.to_sym
      a.cover_url = covers[key]
    end
    albums
  end
end



#
# WretchDLAppMain Class: WretchDL App main code.
#
class WretchDLAppMain
  def initialize
    # app version number
    @version = "0.9.1"
  end
  
  # app start
  def start
    puts "- WretchDL Lite v#{@version} by Riddle Ling, 2012."
    while 1 do
      main_code
    end
  end

  private
  # Main Code
  def main_code
    # input Wretch account name.
    begin
      print "\nPlease input Wretch account: "
      wretch_id = gets.chomp
      @page_number = 1
      albums_info = WretchAlbumsInfo.new(wretch_id)
      albums = albums_info.list_of_page(@page_number)
    rescue OpenURI::HTTPError => e
      puts "=> Error: #{e.message}"
      retry
    rescue URI::InvalidURIError => e
      puts "=> Error: #{e.message}"
      retry
    end
    
    show_albums_list(albums)
    num = 0
    
    while 1 do
      # input command.
      print "(#{wretch_id}):p#{@page_number}:#{num}>> "
      input_cmd = gets.chomp
      
      case
      when input_cmd == 'a' || input_cmd == 'A'
        break
      when input_cmd == 'h' || input_cmd == 'H'
        show_help
        next
      when input_cmd == 'q' || input_cmd == 'Q'
        puts "Quit!"
        exit!(0)
      when input_cmd == 'p' || input_cmd == 'P'
        print "Go to Page: "
        @page_number = gets.chomp.to_i
        albums = albums_info.list_of_page(@page_number)
        show_albums_list(albums)
        num = 0
        next
      end
      
      # download album photo.
      album_index = input_cmd.to_i
      if (1..20) === album_index
        num = album_index
        album_index -= 1
        
        start_dir_name = Dir.pwd
        make_and_change_dir(albums_info.wretch_id, albums[album_index].name)
        
        # start download jpg file.
        @count_files = 0
        albums[album_index].photos_urls.each do |photo_url|
          file_url = photo_url.to_file_url
          if file_url.empty? == false
            download_file(file_url)
          end
          sleep 1
        end
        
        puts "\n=> Done! Download the #{@count_files} files!"
        print "Do you want to open \"#{albums[album_index].name}\" directory? (y/n) "
        is_open = gets.chomp
        if is_open == 'y' or is_open == 'Y'
          open_dl_dir
        end
        # goto the start directory.
        Dir.chdir(start_dir_name)
      else
        puts "=> ?"
      end
      
      show_albums_list(albums)
    end # While End
  end # Main Code End


  # make and change dir.
  def make_and_change_dir(id_name, album_name)
    dl_path = "WretchAlbum/#{id_name}/#{album_name}"
    FileUtils.mkdir_p(dl_path)
    
    Dir.chdir(dl_path)
    #puts "Save path: " + Dir.pwd + "/"
  end

  # Download a file.
  def download_file(file_url)
    file_url =~ %r!http://.+/(.+\.jpg)?.+!
    file_name = $1
    puts "Downloading #{file_name}:"
    
    referer_url = "http://www.wretch.cc/album/"
    if system "curl -# --referer #{referer_url} '#{file_url}' -o #{file_name}"
      @count_files += 1
    else
      puts " => Failed!"
    end
  end
  
  # Open save files directory.
  def open_dl_dir
    save_file_dir = Dir.pwd
    os = `uname`
    puts "Open directory: #{save_file_dir}/"
    if os =~ /Darwin/
      system "open '#{save_file_dir}'"
    elsif os =~ /Linux/
      system "xdg-open '#{save_file_dir}'"
    end
  end
  
  # Show albums list.
  def show_albums_list(albums)
    puts "\nAlbums list - page#{@page_number} :"
    albums.each_with_index {|album, i|
      puts " #{i+1}. #{album.name} (#{album.pictures}p)"
      #p album.cover_url
    }
    puts
  end
  
  # Show command list.
  def show_help
    puts "Help:"
    puts "   Keyin 'a' : Changes the Wretch account."
    puts "   Keyin 'h' : Show help."
    puts "   Keyin 'p' : Go to Page."
    puts "   Keyin 'q' : Quit App."
    puts "   Keyin albums index number(1~20) : Download album photos."
    puts
  end
end

WretchDLAppMain.new.start
