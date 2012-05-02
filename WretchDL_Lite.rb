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

#
# WretchAlbumInfo class: Get Wretch Album Info.
#
# Initialize Method:
# initialize(wretch_id) - Setup @wretch_id
#
# Public Method:
# book_list(page_num) - Input: Page number
#                     - Return: album book list (Array):
#                       #=> [[book_number,book_name],[book_number,book_name],...]
#
# photo_urls(book_number) - Input: Book number
#                         - Return: Photo URLs (Array): #=> ["URL", "URL", ...]
#
# get_file_url(photo_url) - Input: Photo URL
#                         - Return: File URL(.jpg file URL)
#
class WretchAlbumInfo
  attr_accessor :wretch_id

  def initialize(wretch_id)
    @wretch_id = wretch_id
  end
  
  # Public: Get book URL and book number.
  # 
  # page_num - Page number.
  #
  # Examples:
  #   obj.book_list(1)
  #   # => [[book_number, book_name], [book_number, book_name], ...]
  #     => "[["123", "Photos01"], ["124", "Photos02"], ...]"
  #
  def book_list(page_num)
    # setup album URL
    wretch_url = "http://www.wretch.cc/album/#{@wretch_id}"
    if page_num >= 2 
      wretch_url << "&page=#{page_num}"
    end

    # get html
    page_data = open(wretch_url)
    page_html = page_data.read
        
    # get book list
    album_books = Array.new

    page_html.each_line {|line|
      if line =~ /<a href="\.\/album\.php\?id=#{@wretch_id}&book=(\d+)">(.+)<\/a>/
        book_name = Regexp.last_match[2]
        book_number = Regexp.last_match[1]
        
        number_and_name = [book_number, book_name]
        album_books.push(number_and_name)
      end
    }
    album_books
  end
  
  # Public: Get Photo URLs.
  #
  # book_number - Book number.
  #
  # Examples:
  #   obj.photo_urls("123")
  #   # => [URL_String, URL_String, ...]
  # 
  def photo_urls(book_number)
    # setup book URL
    book_url = "http://www.wretch.cc/album/album.php?id=#{@wretch_id}&book=#{book_number}"
    i = 1
    n = true
    all_photo_urls = []
    while n do
      # get html
      page_data = open(book_url)
      page_html = page_data.read
    
      all_photo_urls.concat(get_photo_url_list(page_html, book_number))
      i += 1
      n = false
      # Next Page?
      page_html.each_line {|line|
        if line =~ /(album\.php\?id=#{@wretch_id}&book=#{book_number}&page=#{i})/
          book_url = "http://www.wretch.cc/album/album.php?id=#{@wretch_id}&book=#{book_number}&page=#{i}"
           #puts "Next Page: #{book_url}"
          n = true
          break
        end
      }
    end
    all_photo_urls
  end
  
  # Public: Get file URL.
  #
  # photo_url - Photo URL.
  #
  # Examples:
  #   obj.get_file_url("http://...")
  #   # => "http://.../xxxxxxxxxx.jpg?xxxxxxxx..."
  #
  def get_file_url(photo_url)
    page_data = open(photo_url)
    page_html = page_data.read
    
    file_url = ""
    page_html.each_line {|line|
      if line =~ /<img id='DisplayImage' src='([^']+)' /
        file_url = Regexp.last_match[1]
      elsif line =~ /<img class='displayimg' src='([^']+)' /
        file_url = Regexp.last_match[1]
      end
    }
    file_url
  end
  
  private
  
  # Private: Get photo URL list.
  #
  # page_html - Page html.
  # book_number - Book number.
  #
  # Examples:
  #   get_photo_url_list(page_html, "123")
  #   # => ["http://...", "http:/...", ...]
  #
  def get_photo_url_list(page_html, book_number)
    photo_url_list = Array.new
    page_html.each_line {|line|
      if line =~ /<a href="\.\/(show.php\?i=#{@wretch_id}&b=#{book_number}&f=\d+&p=\d+&sp=\d+)".+><img src=/
        photo_url = "http://www.wretch.cc/album/" + Regexp.last_match[1]
        photo_url_list.push(photo_url)
      end
    }
    photo_url_list
  end
end


#
# WretchDLAppController class: WretchDL App main code.
#
class WretchDLAppController
  def initialize
    # app version number
    @version = "0.9.0"
  end
  
  # app start
  def start
    puts "- WretchDL Lite v#{@version} by Riddle Ling, 2012."
    while 1 do
      main_code
    end
  end
  
  private
  
  # main code
  def main_code
    # input Wretch account name.
    begin
      print "\nPlease input Wretch account name: "
      wretch_id = gets.chomp
      now_page_number = 1
      use_album = WretchAlbumInfo.new(wretch_id)
      books = use_album.book_list(now_page_number)
    rescue OpenURI::HTTPError => e
      puts "Error: #{e.message}"
      puts
      retry
    rescue URI::InvalidURIError => e
      puts "Error: #{e.message}"
      puts
      retry
    end
    
    # show book list.
    show_book_list(now_page_number, books)
    
    while 1 do
      # input command.
      print "(#{wretch_id}: p#{now_page_number}), input> "
      input_cmd = gets.chomp
      
      case
      when input_cmd == 'a'
        break
      when input_cmd == 'h'
        show_help
        next
      when input_cmd == "q"
        puts "Quit!"
        exit!(0)
      when input_cmd == "p"
        print "Go to Page: "
        now_page_number = gets.chomp.to_i
        books = use_album.book_list(now_page_number)
        show_book_list(now_page_number, books)
        next
      end
      
      # download files.
      num = input_cmd.to_i
      if (1..20) === num
        num -= 1
        photo_url_arr = use_album.photo_urls(books[num][0])
        start_dir_name = Dir.pwd
        
        # make directory: WretchAlbum
        dl_dir_name = "WretchAlbum"
        unless File.exist?(dl_dir_name) and File.directory?(dl_dir_name)
          # "WretchAlbum" directory is not exist
          Dir.mkdir(dl_dir_name, 0755)
        end
        # cd WretchAlbum directory.
        Dir.chdir(dl_dir_name)
        
        # make directory: using account name
        id_dir_name = use_album.wretch_id
        unless File.exist?(id_dir_name) and File.directory?(id_dir_name)
          # id name directory is not exist
          Dir.mkdir(id_dir_name, 0755)
        end
        # cd id name directory.
        Dir.chdir(id_dir_name)
        
        # make directory: using book name
        bookname_dir_name = books[num][1]
        unless File.exist?(bookname_dir_name) and File.directory?(bookname_dir_name)
          # Book name directory is not exist
          Dir.mkdir(bookname_dir_name, 0755)
        end
        # cd Book name directory.
        Dir.chdir(bookname_dir_name)
        puts "Save path: " + Dir.pwd + "/"
        
        # start download jpg file.
        count_files = 0
        photo_url_arr.each {|photo_url|
          file_url = use_album.get_file_url(photo_url)
          if file_url.empty? == false
            file_url =~ %r!http://.+/(.+\.jpg)?.+!
            file_name = $1
            puts "Downloading #{file_name}:"
            referer_url = "http://www.wretch.cc/album/"
            if system "curl -# --referer #{referer_url} '#{file_url}' -o #{file_name}"
              count_files += 1
            else
              puts " => failed!"
            end
          end
          sleep 1
        }
        puts "\nDone! Download the #{count_files} files!"
        print "Do you want to open \"#{bookname_dir_name}\" directory? (y/n) "
        op = gets.chomp
        if op == 'y' or op == 'Y'
          open_dl_dir
        end
        # goto the start directory.
        Dir.chdir(start_dir_name)
         #puts Dir.pwd
      else
        puts "-> Command Error!"
      end
      # show book list.
      show_book_list(now_page_number, books)
    end # While End
  end
  
  # Open download file directory.
  def open_dl_dir
    save_file_dir = Dir.pwd
    os = `uname`
    puts "Open #{save_file_dir}/ ..."
    if os =~ /Darwin/
      system "open '#{save_file_dir}'"
    elsif os =~ /Linux/
      system "xdg-open '#{save_file_dir}'"
    end
  end
  
  # Show book name list.
  def show_book_list(page_number, book_list_arr)
    puts "\nAlbum book list (page:#{page_number}):"
    book_list_arr.each_index {|i|
      puts " #{i+1}. #{book_list_arr[i][1]}\n"
    }
    puts
  end
  
  # Show command list.
  def show_help
    puts "Help:"
    puts "   Keyin 'a' : Changes the Wretch account name."
    puts "   Keyin 'h' : Show help."
    puts "   Keyin 'p' : Go to Page."
    puts "   Keyin 'q' : Quit App."
    puts "   Keyin album book number(1~20) : Download album book."
    puts
  end
end

my_app = WretchDLAppController.new
my_app.start

