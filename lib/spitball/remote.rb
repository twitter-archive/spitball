require 'net/http'
require 'uri'

class Spitball::Remote

  WAIT_SECONDS = 240

  def initialize(gemfile, host, port)
    @gemfile = gemfile
    @host = host
    @port = port
  end

  def copy_to(path)
    data = generate_remote_tarball
    File.open(path, 'w') { |f| f.write data }
  end

  private

  def generate_remote_tarball
    url = URI.parse("http://#{@host}:#{@port}/create")
    res = Net::HTTP.start(url.host, url.port) do |http|
      http.post(url.path, @gemfile) do |body|
        print body
      end
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

    (WAIT_SECONDS / 2).times do
      if (res = Net::HTTP.get_response(uri)).code == '200'
        return res.body
      else
        sleep 2
      end
    end

    raise Spitball::ServerFailure, "Spitball download timed out."
  end
end
