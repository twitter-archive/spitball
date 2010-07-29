require 'spec/spec_helper'

describe Spitball do
  describe "without_clause" do
    it "returns a --without bundler option if :without is set" do
      Spitball.new('gemfile', :without => "system").without_clause.should == '--without=system'
    end

    it "returns an empty string if without is not set" do
      Spitball.new('gemfile').without_clause.should == ''
    end

    it "allows multiple groups" do
      Spitball.new('gemfile', :without => ["system", "test"]).without_clause.should == '--without=system,test'
    end
  end
end

describe Spitball::FileLock do
  include Spitball::FileLock

  describe "acquire_lock" do
    before do
      Spitball::Repo.make_cache_dir
      @lock_path = File.expand_path('test.lock', SPITBALL_CACHE)
    end

    it "returns true if the lock is acquired" do
      acquire_lock(@lock_path).should == true
    end

    it "returns false if the lock is not acquired" do
      fork { acquire_lock(@lock_path); exit! }
      Process.wait

      acquire_lock(@lock_path).should == false
    end
  end
end

describe Spitball::Repo do
  before do
    Spitball::Repo.make_cache_dir
  end

  describe "make_cache_dir" do
    it "creates the correct cache dir" do
      FileUtils.rm_rf(SPITBALL_CACHE)

      File.exist?(SPITBALL_CACHE).should_not == true
      Spitball::Repo.make_cache_dir
      File.exist?(SPITBALL_CACHE).should == true
    end
  end

  describe "path" do
    it "generates paths with the correct cache" do
      Spitball::Repo.path('digest').should =~ %r[^#{SPITBALL_CACHE}]
    end

    it "generates paths with extensions" do
      Spitball::Repo.path('digest', 'tgz').should =~ %r[\.tgz$]
    end

    it "generates paths prefixed with bundle_" do
      Spitball::Repo.path('digest', 'tgz').should =~ %r[bundle_digest\.tgz$]
    end
  end

  describe "exist?" do
    it "returns true if tarball for a digest has been exists" do
      Spitball::Repo.exist?('digest').should_not == true
      File.open(Spitball::Repo.path('digest', 'tgz'), 'w') {|f| f.write 'tarball!' }
      Spitball::Repo.exist?('digest').should == true
    end
  end

  describe "gemfile" do
    it "returns the contents of the cached gemfile for a digest" do
      gemfile = 'gem :memcached'
      File.open(Spitball::Repo.path('digest', 'gemfile'), 'w') {|f| f.write gemfile }
      Spitball::Repo.gemfile('digest').should == gemfile
    end
  end

  describe "list_cached" do
    it "returns a list of cached bundles" do
      File.open(Spitball::Repo.path('digest', 'tgz'), 'w') {|f| f.write 'tarball!' }
      File.open(Spitball::Repo.path('digest2', 'tgz'), 'w') {|f| f.write 'tarball2!' }

      Spitball::Repo.list_cached.should == ['digest', 'digest2']
    end
  end
end

describe Spitball::Digest do
  it "generates a digest based on the spitball's options and gemfile" do
    [Spitball.new('gemfile contents', :without => "system").digest,
     Spitball.new('gemfile contents 2', :without => "system").digest,
     Spitball.new('gemfile', :without => "other_group").digest,
     Spitball.new('gemfile').digest
    ].uniq.length.should == 4
  end

  it "provides a hash equal to the digest's hash"do
    spitball = Spitball.new('gemfile contents')
    spitball.hash.should == spitball.digest.hash
  end
end
