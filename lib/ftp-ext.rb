%w(rubygems net/ftp ptools).each do |lib|
  require lib
end

module Net
  class FTP
    def put_dir(opts = {})
      # Set default options
      options = {
        :local     => ".",
        :remote    => ".",
        :verbose   => false,
        :erase     => false
      }.merge!(opts)
            
      # Check for existence of directory on remote server
      # and create it if it isn't there. If it does exist,
      # call sync_dir instead.
      if !remote_file_exists?(options[:remote])
        file_segments = options[:remote].split(File::SEPARATOR)
        
        # Make directory and all missing parent directories
        file_segments.length.times do |n|
          fpath = File.join(file_segments[0..n])
          
          unless remote_file_exists?(fpath) || fpath == ""
            puts "mkdir #{fpath}" if options[:verbose] == true
            mkdir(fpath)
          end
        end
      else
        options[:erase] ? (rmrf_dir(options[:remote], options[:verbose]); put_dir(options)) : sync_dir(options)
        return
      end
      
      # Upload files recursively
      Dir.foreach(options[:local]) do |f|
        local  = File.join(options[:local], f)
        remote = File.join(options[:remote], f)

        if File.file?(local)
          puts "cp #{remote}" if options[:verbose] == true
          File.binary?(local) ? putbinaryfile(local, remote) : puttextfile(local, remote)
          
        # ignore . and .., but upload other directories
        elsif !f.match(/^\.+$/)
          put_dir(options.merge({ :local => local, :remote => remote }))
        end
        
      end
      
    end
    
    def rmrf_dir(dir, verbose = false)
      return if !remote_file_exists?(dir)
      
      # Get file list from the server and begin deleting files
      begin
        flist = nlst(dir)
        
        flist.each do |f|
          # Ignore . and ..
          next if f.match(/^\.+$/)
          
          # Try to delete the file. If we fail then it's a directory
          begin
            delete(f)
            puts "rm #{f}" if verbose
          rescue Exception => e
            rmrf_dir(f, verbose)
          end
          
        end
      rescue Exception => e
        # If the directory is empty, error silently and continue execution
      end
      
      rmdir(dir)
      puts "rm -rf #{dir}" if verbose
      
    end
    
    protected
    def sync_dir(options = {})
      # Loop through each directory and compare/update the files
      Dir.foreach(options[:local]) do |f|
        local  = File.join(options[:local], f)
        remote = File.join(options[:remote], f)
        
        if File.file?(local)
          if !remote_file_exists?(remote) || mtime(remote) < File.mtime(local)
            puts "updating #{remote}" if options[:verbose] == true
            File.binary?(local) ? putbinaryfile(local, remote) : puttextfile(local, remote)
            
          else
            puts "skipping #{remote}" if options[:verbose] == true
          end
        elsif !f.match(/^\.+$/)
          put_dir(options.merge(:local => local, :remote => remote))
        end
      
      end
      
    end
    
    def remote_file_exists?(file)
      fpath = file.split(File::SEPARATOR)

      # If we're only one directory deep, don't try to join anything
      if fpath.length == 1
        # starting at file system root?
        if file.match(/^#{File::SEPARATOR}/)
          return nlst(File::SEPARATOR).include?(file)
        # starting relative to FTP dir
        else
          return nlst.include?(file)
        end
      # Nested directories
      else
        fname = fpath.pop
        fpath.map! { |v| v == "" ? File::SEPARATOR : v }
        fpath = fpath.join(File::SEPARATOR)

        # Wrap return in begin..rescue because nlst errors on empty directory
        begin
          return nlst(fpath).include?(File.join(fpath, fname))
        rescue Exception => e
          return false if e.message.match("450")
        end

      end

    end
    
  end
end