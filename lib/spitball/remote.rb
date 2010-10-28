require 'net/http'
require 'uri'

class Spitball::Remote

  def initialize(gemfile, gemfile_lock, opts = {})
    @gemfile = gemfile
    @gemfile_lock = gemfile_lock
    @host = opts[:host]
    @port = opts[:port]
  end

  def copy_to(path)
    case path
    when /\.tar\.gz$/, /\.tgz$/
      data = generate_remote_tarball
      File.open(path, 'w') { |f| f.write data }
    else
      begin
        File.open('tmp.tgz', 'w') { |f| f.write data }
        FileUtils.mkdir_p path
        `tar xvf tmp.tgz -C #{path}`
      ensure
        FileUtils.rm_rf('tmp.tgz')
      end
    end
  end

  private

  def generate_remote_tarball
    url = URI.parse("http://#{@host}:#{@port}/create")
    req = Net::HTTP::Post.new(url.path)
    req.form_data = {'gemfile' => @gemfile, 'gemfile_lock' => @gemfile_lock}

    res = Net::HTTP.new(url.host, url.port).start do |http|
      http.request(req) {|r| puts r.read_body }
    end

    print "\nDownloading tarball..."; $stdout.flush

    data =
      case res.code
      when '201', '202' # Created, Accepted
        get_tarball_data res['Location']
      else
        raise Spitball::ServerFailure, "Expected 2xx response code. Got #{res.code}."
      end

    puts "done."

    data
  rescue URI::InvalidURIError => e
    raise Spitball::ClientError, e.message
  end

  def get_tarball_data(location)
    uri = URI.parse(location)

    if (res = Net::HTTP.get_response(uri)).code == '200'
      return res.body
    else
      raise Spitball::ServerFailure, "Spitball download failed."
    end
  end
end
