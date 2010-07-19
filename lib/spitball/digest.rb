require 'digest/sha1'

module Spitball::Digest
  def digest
    @digest ||= ::Digest::SHA1.hexdigest "#{options.to_a.sort}:#{gemfile}"
  end

  def hash
    digest.hash
  end
end
