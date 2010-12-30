require 'helper'

class FTPExtTest < Test::Unit::TestCase
  context "FTPExt should" do

    setup do
      @src = 'htdocs'
    end

    should "upload a directory to a linux machine" do
      ftp = Net::FTP.new('localhost')
      ftp.login('testuser', 'testpass')
      
      ftp.put_dir(@src)
      puts ftp.nlst
      assert true
    end
  end
end