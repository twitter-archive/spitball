require 'net/http'
require 'uri'
require 'digest/md5'

class Spitball::Remote

  include Spitball::ClientCommon

  def initialize(gemfile, gemfile_lock, opts = {})
    @gemfile, @gemfile_lock = gemfile, gemfile_lock
    @host      = opts[:host]
    @port      = opts[:port]
    @without   = (opts[:without] || []).map{|w| w.to_sym}
    @cache_dir = ENV['SPITBALL_CACHE'] || "/tmp/spitball-#{ENV['USER']}/client"
    FileUtils.mkdir_p(@cache_dir)
    use_cache_file
  end

  def use_cache_file
    if File.exist?(cache_file)
      @tarball_url = cache_file
    end
  end

  def cache_file
    hash = ::Digest::MD5.hexdigest(([@host, @port, @gemfile, @gemfile_lock, Spitball::PROTOCOL_VERSION] + @without).join('/'))
    File.join(@cache_dir, hash)
  end

  def cached?
    !!@tarball_url
  end

  def cache!(sync = true) # ignore sync
    return if cached?

    url = "http://#{@host}:#{@port}/create"
    begin
      url = URI.parse(url)
      req = Net::HTTP::Post.new(url.path)
      req.form_data = {'gemfile' => @gemfile, 'gemfile_lock' => @gemfile_lock}
      req.add_field Spitball::PROTOCOL_HEADER, Spitball::PROTOCOL_VERSION
      req.add_field Spitball::WITHOUT_HEADER, @without.join(',')

      res = Net::HTTP.new(url.host, url.port).start do |http|
        http.read_timeout = 3000
        http.request(req) {|r| puts r.read_body }
      end

      case res.code
      when '201', '202' # Created, Accepted
        @tarball_url = res['Location']
      when '301', '302'
        url = res['Location']
      when '403'
      else
        raise Spitball::ServerFailure, "Expected 2xx response code. Got #{res.code}."
      end
    end while @tarball_url.nil?
  rescue URI::InvalidURIError => e
    raise Spitball::ClientError, e.message
  end

  private

  def copy_tarball_data(path)
    cache!
    print "\nDownloading tarball..."; $stdout.flush
    data = get_tarball_data @tarball_url
    puts "done."

    File.open(path, 'w') { |f| f.write data }
  end

  def get_tarball_data(location)
    if File.exist?(location)
      File.read(location)
    else
      uri = URI.parse(location)

      code = (res = Net::HTTP.get_response(uri)).code
      if code == '200'
        File.open(cache_file, 'w') {|f| f << res.body}
        return res.body
      elsif code == '301' || code == '302'
        return get_tarball_data(res['Location'])
      else
        raise Spitball::ServerFailure, "Spitball download failed."
      end
    end
  #rescue URI::InvalidURIError => e
  #  raise Spitball::ClientError, e.message
  end
end
