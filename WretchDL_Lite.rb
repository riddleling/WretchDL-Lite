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
# BookInfo Class: Wretch Album a book info.
#
# Initialize Method:
# initialize(book_number, book_name) - Setup @book_number and @book_name
#
class BookInfo
  attr_accessor :book_number, :book_name
  
  def initialize(book_number, book_name)
    @book_number, @book_name = book_number, book_name
  end
end



#
# WretchAlbumsInfo Class: Get Wretch Albums Info.
#
# Initialize Method:
# initialize(wretch_id) - Setup @wretch_id
#
# Public Method:
# book_list(page_num) - Input: Page number
#                     - Return: album books list (Array):
#                       #=> [BookInfo object, BookInfo object, ...]
#
# photo_urls(book_number) - Input: Book number
#                         - Return: Photo URLs (Array): #=> ["URL", "URL", ...]
#
# get_file_url(photo_url) - Input: Photo URL
#                         - Return: File URL(.jpg file URL)
#
class WretchAlbumsInfo
  attr_accessor :wretch_id

  def initialize(wretch_id)
    @wretch_id = wretch_id
  end
  
  # Public: Get book URL and book number.
  # 
  # page_num - Page number.
  #
  # Examples:
  #   obj.books_list(1)
  #   # => [BookInfo object, BookInfo object, ...]
  #
  def books_list(page_num)
    # setup album URL
    wretch_url = "http://www.wretch.cc/album/#{@wretch_id}"
    if page_num >= 2 
      wretch_url << "&page=#{page_num}"
    end

    # get html
    page_html = open(wretch_url).read
        
    # get books list
    album_books = Array.new

    page_html.each_line {|line|
      if line =~ /<a href="\.\/album\.php\?id=#{@wretch_id}&book=(\d+)">(.+)<\/a>/
        album_books << BookInfo.new(Regexp.last_match[1], Regexp.last_match[2])
      end
    }
    album_books
  end
  
  # Public: Get Photo URLs.
  #
  # book_number - Book number.
  #
  # Examples:
  #   obj.book_photos_urls("123")
  #   # => [URL_String, URL_String, ...]
  # 
  def book_photos_urls(book_number)
    # setup book URL
    book_url = "http://www.wretch.cc/album/album.php?id=#{@wretch_id}&book=#{book_number}"
    i = 1
    n = true
    photos_urls = []
    while n do
      # get html
      page_html = open(book_url).read
    
      photos_urls.concat(get_photo_url_list(page_html, book_number))
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
    photos_urls
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
# WretchDLAppController Class: WretchDL App main code.
#
class WretchDLAppController
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
      print "\nPlease input Wretch account name: "
      wretch_id = gets.chomp
      @page_number = 1
      album = WretchAlbumsInfo.new(wretch_id)
      books = album.books_list(@page_number)
    rescue OpenURI::HTTPError => e
      puts "=> Error: #{e.message}"
      retry
    rescue URI::InvalidURIError => e
      puts "=> Error: #{e.message}"
      retry
    end
    
    show_books_list(books)
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
        books = album.books_list(@page_number)
        show_books_list(books)
        num = 0
        next
      end
      
      # download album book photo.
      book_index = input_cmd.to_i
      if (1..20) === book_index
        num = book_index
        book_index -= 1
        
        start_dir_name = Dir.pwd
        make_and_change_dir(album.wretch_id, books[book_index].book_name)
        
        # start download jpg file.
        @count_files = 0
        album.book_photos_urls(books[book_index].book_number).each {|photo_url|
          file_url = album.get_file_url(photo_url)
          if file_url.empty? == false
            download_file(file_url)
          end
          sleep 1
        }
        
        puts "\n=> Done! Download the #{@count_files} files!"
        print "Do you want to open \"#{books[book_index].book_name}\" directory? (y/n) "
        open_dir = gets.chomp
        if open_dir == 'y' or open_dir == 'Y'
          open_dl_dir
        end
        # goto the start directory.
        Dir.chdir(start_dir_name)
      else
        puts "=> ?"
      end
      
      show_books_list(books)
    end # While End
  end # Main Code End


  # make and change dir.
  def make_and_change_dir(id_name, book_name)
    # make directory: WretchAlbum
    dl_dir_name = "WretchAlbum"
    unless File.exist?(dl_dir_name) and File.directory?(dl_dir_name)
      Dir.mkdir(dl_dir_name, 0755)
    end
    # cd WretchAlbum directory.
    Dir.chdir(dl_dir_name)
        
    # make directory: using account name
     #id_dir_name = album.wretch_id
    unless File.exist?(id_name) and File.directory?(id_name)
      Dir.mkdir(id_name, 0755)
    end
    # cd id name directory.
    Dir.chdir(id_name)
        
    # make directory: using book name
     #bookname_dir_name = books[book_index].book_name
    unless File.exist?(book_name) and File.directory?(book_name)
      Dir.mkdir(book_name, 0755)
    end
    # cd Book name directory.
    Dir.chdir(book_name)
     # puts "Save path: " + Dir.pwd + "/"
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
  
  # Show book name list.
  def show_books_list(books)
    puts "\nAlbum book list (page:#{@page_number}):"
    books.each_index {|i|
      puts " #{i+1}. #{books[i].book_name}"
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

WretchDLAppController.new.start
