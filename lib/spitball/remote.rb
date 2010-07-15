require 'net/http'
require 'uri'

class Spitball::Remote

  def initialize(gemfile, host)
    @gemfile = gemfile
    @host = host
  end

  def copy_to(path)
    File.open(path, 'w') do |f|
      f.write get_tarball_data
    end
  end

  def get_tarball_data
    url = URI.parse("http://#{@host}/create")
    res = Net::HTTP.start(url.host, url.port) do |http|
      http.post(url.path, @gemfile)
    end

    case res.code
    when '201' # Created
      Net::HTTP.get(URI.parse(res['Location']))
    when '202' # Accepted
      loop do
        sleep 2
        try = Net::HTTP.get_response(URI.parse(res['Location']))
        next if try.code != '200'
        return try.body
      end
    else
      raise SpitballServerFailure, "Expected 2xx response code. Got #{res.code}."
    end
  end

end
