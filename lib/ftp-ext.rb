%w{rubygems net/ftp ptools}.each do |lib|
  require lib
end

module Net
  class FTP
    
    def put_dir(local_folder, remote_folder = '.')
      rmdir(File.join(remote_folder, local_folder)) if file_exists? File.join(remote_folder, local_folder)
      
      Dir.chdir(local_folder)
      chdir(remote_folder)

      mkdir(File.basename(local_folder))
      chdir(File.basename(local_folder))

      Dir.foreach('.') do |f|      
        if File.file?(f)
          File.binary?(f) ? putbinaryfile(f) : puttextfile(f)
        elsif !f.match(/^\.+$/)
          put_dir(File.path(f))
        end
      end

      Dir.chdir('..')
      chdir('..')
    end

    def sync_dir(local_folder, remote_folder = '.')
      mkdir(remote_folder) if !file_exists?(remote_folder)
      
      Dir.chdir(local_folder)
      chdir(remote_folder)
      
      Dir.foreach('.') do |f|
        if File.file?(f)
          if !file_exists?(f) || mtime(f) < File.mtime(f)
            File.binary?(f) ? putbinaryfile(f) : puttextfile(f)
          end
        elsif !f.match(/^\.+$/)
          mkdir(File.basename(f)) if !file_exists?(f)
          sync_dir(File.path(f), f)
        end
      end
      
      Dir.chdir('..')
      chdir('..')
    end
    
    protected
    def file_exists?(file)
      list = nlst
      nlst.include?(file)
    end
    
  end
end