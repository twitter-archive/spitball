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
    data = generate_remote_tarball
    File.open(path, 'w') { |f| f.write data }
  end

  private

  def generate_remote_tarball
    res = Net::HTTP.post_form(URI.parse("http://#{@host}:#{@port}/create"), {'gemfile' => @gemfile, 'gemfile_lock' => @gemfile_lock})

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
