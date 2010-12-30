%w(rubygems net/ftp ptools).each do |lib|
  require lib
end

module Net
  class FTP
    def put_dir(local, remote = ".", erase = false)
      dirname = File.basename(local)
      current_local  = Dir.pwd
      current_remote = pwd
      
      # Change directory
      Dir.chdir(local)
      chdir(remote)
      
      # Make new directory or, if it exists, begin sync
      begin
        mkdir(dirname)
      rescue Exception => e
        Dir.chdir(current_local)
        chdir(current_remote)
        sync_dir(local, dirname)
        return
      end
      chdir(dirname)
      
      # Upload files recursively
      Dir.foreach(".") do |f|
        if File.file?(f)
          File.binary?(f) ? putbinaryfile(f) : puttextfile(f)
        elsif !f.match(/^\.+$/)
          put_dir(f, pwd)
        end
      end
      
      # Clean up
      Dir.chdir('..')
      chdir('..')
    end
    
    def sync_dir(local, remote = ".")
      # Change directory
      Dir.chdir(local)
      chdir(remote)
      
      # Loop through directory and compare/update files
      Dir.foreach(".") do |f|
        if File.file?(f)
          # Add new files and replace old files
          if !file_exists?(f) || mtime(f) < File.mtime(f)
            File.binary?(f) ? putbinaryfile(f) : puttextfile(f)
          end
        # Recurse if the file is a directory
        elsif !f.match(/^\.+$/)
          mkdir(File.basename(f)) if !file_exists?(f)
          sync_dir(f, File.join(pwd, f))
        end
      end
      
      # Clean up
      Dir.chdir("..")
      chdir("..")

    end

    protected
    def file_exists?(file)
      list = nlst
      nlst.include?(file)
    end
    
  end
end