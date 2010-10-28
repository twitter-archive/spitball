require 'net/http'
require 'uri'

class Spitball::Remote

  include Spitball::ClientCommon

  def initialize(gemfile, gemfile_lock, opts = {})
    @gemfile = gemfile
    @gemfile_lock = gemfile_lock
    @host = opts[:host]
    @port = opts[:port]
  end

  def cached?
    !!@tarball_url
  end

  def cache!(sync = true) # ignore sync
    return if cached?

    url = URI.parse("http://#{@host}:#{@port}/create")
    req = Net::HTTP::Post.new(url.path)
    req.form_data = {'gemfile' => @gemfile, 'gemfile_lock' => @gemfile_lock}

    res = Net::HTTP.new(url.host, url.port).start do |http|
      http.request(req) {|r| puts r.read_body }
    end

    case res.code
    when '201', '202' # Created, Accepted
      @tarball_url = res['Location']
    else
      raise Spitball::ServerFailure, "Expected 2xx response code. Got #{res.code}."
    end
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
    uri = URI.parse(location)

    if (res = Net::HTTP.get_response(uri)).code == '200'
      return res.body
    else
      raise Spitball::ServerFailure, "Spitball download failed."
    end
  rescue URI::InvalidURIError => e
    raise Spitball::ClientError, e.message
  end
end
