# WretchDL Lite

下載 Wretch 相簿的小程式。

## 系統需求

Mac OS X 或 Linux，且需要有安裝 curl 與 Ruby 1.8.7+

## 使用方式

Ubuntu 使用者需要先安裝 Ruby 與 curl：

    $ sudo apt-get install ruby1.9.1
    $ sudo apt-get install curl

執行 WretchDL Lite：

    $ ./WretchDL_Lite.rb

接著輸入欲下載的相簿的 Wretch 帳號，例如(假設帳號是riddleapple)：

    Please input Wretch account: riddleapple

輸入帳號後，會輸出第一頁的相簿列表，例如：

    Albums list - page1 :
     1. 小時候的相片 (10p)
     2. 出遊照 (30p)
     3. 搞怪照 (9p)
     4. 雜七雜八 (35p)
     5. 風景照 (20p)
     
    (riddleapple):p1:0>>

輸入相簿編號，就可以開始下載相簿。例如想要下載上述列表的``小時候的相片``，就輸入``1``：

    (riddleapple):p1:0>> 1

下載的相簿會儲存在現行資料夾裡的``WretchAlbum``資料夾裡。


輸入``h``會顯示 Help 內容：

    (riddleapple):p1:1>> h
    Help:
      Keyin 'a' : Changes the Wretch account.
      Keyin 'h' : Show help.
      Keyin 'p' : Go to Page.
      Keyin 'q' : Quit App.
      Keyin albums index number(1~20) : Download album photos.

輸入``p``可以切換頁面。例如想要顯示第二頁的相簿列表時：

    (riddleapple):p1:1>> p
    Go to Page: 2

輸入``a``可以切換 Wretch 帳號：

    (riddleapple):p1:1>> a
    Please input Wretch account: 這裡輸入 Wretch 帳號

輸入``q``會結束程式：

    (riddleapple):p1:1>> q
    Quit!

## 軟體授權 (License)

本專案程式碼採用 MIT License 釋出。