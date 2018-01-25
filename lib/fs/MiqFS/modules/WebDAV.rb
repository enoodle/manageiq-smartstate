require 'uri'
require 'net/http'

require 'fs/MiqFS/modules/WebDAVFile'

module WebDAV
  attr_reader :guestOS

  def fs_init
    @fsType = "WebDAV"
    @guestOS = @dobj.guest_os

    @uri = URI(@dobj.uri.to_s)
    @headers = @dobj.headers || {}

    @connection = Net::HTTP.start(
      @uri.host,
      @uri.port,
      @dobj.http_options
    )
  end

  def fs_unmount
    @connection.finish
  end

  def freeBytes
    0
  end

  def fs_dirEntries(_path)
    raise NotImplementedError
  end

  def fs_fileExists?(path)
    response = WebDAVFile.head_response(@connection, remote_uri(path), @headers)
    case response
    when Net::HTTPOK
      return true
    when Net::HTTPMethodNotAllowed # some servers return this for directories
      return true
    when Net::HTTPNotFound
      return false
    else
      raise Errno::EINVAL
    end
  end

  def fs_fileDirectory?(path)
    # TODO: implement proper check for being a directory
    path += '/' unless path.end_with?('/')
    fs_fileExists?(path)
  end

  def fs_fileFile?(_path)
    raise NotImplementedError
  end

  def fs_fileSize(path)
    WebDAVFile.file_size(remote_uri(path))
  end

  def fs_fileSize_obj(fobj)
    fobj.size
  end

  def fs_fileAtime(_path)
    raise NotImplementedError
  end

  def fs_fileCtime(_path)
    raise NotImplementedError
  end

  def fs_fileMtime(_path)
    raise NotImplementedError
  end

  def fs_fileAtime_obj(_fobj)
    raise NotImplementedError
  end

  def fs_fileCtime_obj(_fobj)
    raise NotImplementedError
  end

  def fs_fileMtime_obj(_fobj)
    raise NotImplementedError
  end

  def fs_fileOpen(path, mode = "r")
    raise Errno::EACCES unless mode == 'r'
    WebDAVFile.new(remote_uri(path), @dobj.http_options, @headers)
  end

  def fs_fileSeek(fobj, offset, whence)
    fobj.seek(offset, whence)
  end

  def fs_fileRead(fobj, len)
    fobj.read(len)
  end

  def fs_fileClose(fobj)
    fobj.close
  end

  def fs_fileWrite(_fobj, _buf, _len)
    raise Errno::EACCES
  end

  def fs_dirMkdir(_path)
    raise Errno::EACCES
  end

  def dirRmdir(_path)
    raise Errno::EACCES
  end

  def fs_fileDelete(_path)
    raise Errno::EACCES
  end

  private

  def remote_uri(path)
    @uri.merge(@uri.path + path)
  end
end
