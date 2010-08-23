require 'spec/spec_helper'

describe Spitball do
  before do
    use_success_bundler

    @gemfile = <<-end_gemfile
        source :rubygems
        gem "activerecord"
      end_gemfile

    @spitball = Spitball.new(@gemfile)
  end

  describe "cached?" do
    it "returns true if the tarball has already been cached" do
      @spitball.should_not be_cached
      @spitball.cache!
      @spitball.should be_cached
    end
  end

  describe "cache!" do
    it "returns if the spitball is cached" do
      mock(@spitball).cached? { true }
      mock.instance_of(Spitball::FileLock).acquire_lock.never
      mock.instance_of(Spitball::FileLock).release_lock.never
      mock(@spitball).create_bundle(anything).never

      @spitball.cache!
    end

    it "creates the bundle if it acquires the lock" do
      mock.instance_of(Spitball::FileLock).acquire_lock { true }
      mock(@spitball).create_bundle
      mock.instance_of(Spitball::FileLock).release_lock

      @spitball.cache!
    end

    it "does not create the bundle if it does not acquire the lock" do
      mock.instance_of(Spitball::FileLock).release_lock.never
      mock.instance_of(Spitball::FileLock).acquire_lock { false }
      mock(@spitball).create_bundle.never

      @spitball.cache!(false)
    end

    it "blocks if it does not acquire the lock and sync is true (default)" do
      cached = false
      done_caching = false

      mock.instance_of(Spitball::FileLock).acquire_lock { false }
      stub(@spitball).cached? { cached }

      t = Thread.new do
        @spitball.cache!
        done_caching = true
      end

      sleep 0.5
      done_caching.should_not == true

      cached = true
      t.join
      done_caching.should == true
    end
  end

  describe "create_bundle" do
    it "generates a bundle at the bundle_path" do
      @spitball.create_bundle

      File.exist?(@spitball.tarball_path).should == true
    end

    it "raises an exception if bundle creation fails" do
      use_fail_bundler

      lambda { @spitball.create_bundle }.should raise_error(Spitball::BundleCreationFailure)
      File.exist?(@spitball.tarball_path).should_not == true
    end
  end

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
  describe "acquire_lock" do
    before do
      Spitball::Repo.make_cache_dir
      @lock_path = File.expand_path('test.lock', SPITBALL_CACHE)
      @lock = Spitball::FileLock.new(@lock_path)
    end

    it "returns true if the lock is acquired" do
      @lock.acquire_lock.should == true
    end

    it "returns false if the lock is not acquired" do
      fork { @lock.acquire_lock; exit! }
      Process.wait

      @lock.acquire_lock.should == false
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
    it "returns true if tarball for a digest exists" do
      Spitball::Repo.exist?('digest').should_not == true
      File.open(Spitball::Repo.path('digest', 'tgz'), 'w') {|f| f.write 'tarball!' }
      Spitball::Repo.exist?('digest').should == true
    end
  end

  describe "tarball" do
    it "returns the path of the cached tarball for a digest" do
      Spitball::Repo.tarball('digest').should == Spitball::Repo.path('digest', 'tgz')
    end
  end

  describe "gemfile" do
    it "returns the path of the cached gemfile for a digest" do
      Spitball::Repo.gemfile('digest').should == Spitball::Repo.path('digest', 'gemfile')
    end
  end

  describe "cached_digests" do
    it "returns a list of cached bundles" do
      File.open(Spitball::Repo.tarball('digest'), 'w') {|f| f.write 'tarball!' }
      File.open(Spitball::Repo.tarball('digest2'), 'w') {|f| f.write 'tarball2!' }

      Spitball::Repo.cached_digests.should == ['digest', 'digest2']
    end
  end

  describe "clean_up_unused" do
    it "removes cached tarballs and gemfiles that haven't been accessed within a certain period" do
      File.open(Spitball::Repo.tarball('digest'), 'w') {|f| f.write 'tarball!' }
      File.open(Spitball::Repo.gemfile('digest'), 'w') {|f| f.write 'gemfile!' }

      sleep 2
      File.open(Spitball::Repo.tarball('digest2'), 'w') {|f| f.write 'tarball2!' }
      File.open(Spitball::Repo.gemfile('digest2'), 'w') {|f| f.write 'gemfile2!' }

      Spitball::Repo.clean_up_unused(1)

      File.exist?(Spitball::Repo.tarball('digest')).should_not == true
      File.exist?(Spitball::Repo.gemfile('digest')).should_not == true
      File.exist?(Spitball::Repo.tarball('digest2')).should == true
      File.exist?(Spitball::Repo.gemfile('digest2')).should == true
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
