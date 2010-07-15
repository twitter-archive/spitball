require 'digest/sha1'

module Spitball::Digest
  def digest
    @digest ||= ::Digest::SHA1.hexdigest gemfile
  end

  def hash
    digest.hash
  end
end
