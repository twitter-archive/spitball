module Spitball::ClientCommon
  def copy_to(path)
    case path
    when /\.tar\.gz$/, /\.tgz$/
      copy_tarball_data(path)
    else
      tmp_tgz = File.join(path, 'spitball.tgz')
      FileUtils.mkdir_p path

      copy_tarball_data(tmp_tgz)
      `tar xzf #{tmp_tgz} -C #{path}`

      FileUtils.rm_rf(tmp_tgz)
    end
  end

  def cached?
    raise NotImplementedError
  end

  def cache!
    raise NotImplementedError
  end

  private

  def copy_tarball_data(path)
    raise NotImplementedError
  end
end
