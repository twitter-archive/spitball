require './spec/spec_helper'

describe Spitball do
  before do
    use_success_bundler

    @gemfile = <<-end_gemfile
        source :rubygems
        gem "json_pure"
      end_gemfile

    @lockfile = <<-end_lockfile.strip.gsub(/\n[ ]{6}/m, "\n")
      GEM
        remote: http://rubygems.org/
        specs:
          json_pure (1.4.6)

      PLATFORMS
        ruby

      DEPENDENCIES
        json_pure
    end_lockfile

    @spitball = Spitball.new(@gemfile, @lockfile)
  end

  describe "cached?" do
    it "returns true if the tarball has already been cached" do
      @spitball.should_not be_cached
      mock(@spitball).install_gem(anything).times(any_times)
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

      sleep 0.1
      done_caching.should_not == true

      cached = true
      t.join
      done_caching.should == true
    end
  end

  describe "generate_build_args" do
    it "returns an empty string for nil" do
      @spitball.send(:generate_build_args, nil).should == ''
    end

    it "returns arguments prepended with double dashes for a string" do
      @spitball.send(:generate_build_args, '--build-args=joesmith').should == '-- --build-args=joesmith'
    end
  end

  describe "create_bundle" do
    it "generates a bundle at the bundle_path" do
      mock(@spitball).install_gem(anything).times(any_times)
      capture_stdout { @spitball.send :create_bundle }
      File.exist?(@spitball.send(:tarball_path)).should == true
    end
  end

  describe "without_clause" do
    before do
      @gemfile = <<-end_gemfile
          source :rubygems
          group 'development' do
            gem "activerecord"
          end
        end_gemfile

      @lockfile = <<-end_lockfile.strip.gsub(/\n[ ]{8}/m, "\n")
        GEM
          remote: http://rubygems.org/
          specs:
            activemodel (3.0.1)
              activesupport (= 3.0.1)
              builder (~> 2.1.2)
              i18n (~> 0.4.1)
            activerecord (3.0.1)
              activemodel (= 3.0.1)
              activesupport (= 3.0.1)
              arel (~> 1.0.0)
              tzinfo (~> 0.3.23)
            activesupport (3.0.1)
            arel (1.0.1)
              activesupport (~> 3.0.0)
            builder (2.1.2)
            i18n (0.4.2)
            tzinfo (0.3.23)

        PLATFORMS
          ruby

        DEPENDENCIES
          activerecord
      end_lockfile
    end

    it "should use without" do
      @spitball = Spitball.new(@gemfile, @lockfile)
      mock(@spitball).install_and_copy_spec(anything, anything).times(9)
      @spitball.send :create_bundle
      @spitball = Spitball.new(@gemfile, @lockfile, :without => 'development')
      mock(@spitball).install_and_copy_spec(anything).times(0)
      @spitball.send :create_bundle
    end
  end

  context "sources_opt" do
    it "does not add --clear sources for rubygems >= 1.4.0" do
      @spitball = Spitball.new(@gemfile, @lockfile)
      parsed_lockfile =  @spitball.instance_variable_get("@parsed_lockfile")
      Gem::VERSION = "1.3.10"
      @spitball.send(:sources_opt, parsed_lockfile.sources).should == "--source http://rubygems.org/"
    end

    it "adds --clear sources for rubygems >= 1.4.0" do
      @spitball = Spitball.new(@gemfile, @lockfile)
      parsed_lockfile =  @spitball.instance_variable_get("@parsed_lockfile")
      Gem::VERSION = "1.4.0"
      @spitball.send(:sources_opt, parsed_lockfile.sources).should == "--clear-sources --source http://rubygems.org/"
    end
  end
end

describe Spitball::FileLock do
  describe "acquire_lock" do
    before do
      Spitball::Repo.make_cache_dirs
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
    Spitball::Repo.make_cache_dirs
  end

  describe "make_cache_dirs" do
    it "creates the correct cache dir" do
      FileUtils.rm_rf(SPITBALL_CACHE)

      File.exist?(SPITBALL_CACHE).should_not == true
      Spitball::Repo.make_cache_dirs
      File.exist?(SPITBALL_CACHE).should == true
    end
  end

  describe "bundle_path" do
    it "generates paths with the correct cache" do
      Spitball::Repo.bundle_path('digest').should =~ %r[^#{SPITBALL_CACHE}]
    end

    it "generates paths with extensions" do
      Spitball::Repo.bundle_path('digest', 'tgz').should =~ %r[\.tgz$]
    end

    it "generates paths prefixed with bundle_" do
      Spitball::Repo.bundle_path('digest', 'tgz').should =~ %r[bundle_digest\.tgz$]
    end
  end

  describe "gemcache_path" do
    it "returns the correct path in the cache dir" do
      Spitball::Repo.gemcache_path.should == File.join(SPITBALL_CACHE, "gemcache")
    end
  end

  describe "exist?" do
    it "returns true if tarball for a digest exists" do
      Spitball::Repo.exist?('digest').should_not == true
      File.open(Spitball::Repo.bundle_path('digest', 'tgz'), 'w') {|f| f.write 'tarball!' }
      Spitball::Repo.exist?('digest').should == true
    end
  end

  describe "tarball" do
    it "returns the path of the cached tarball for a digest" do
      Spitball::Repo.tarball('digest').should == Spitball::Repo.bundle_path('digest', 'tgz')
    end
  end

  describe "gemfile" do
    it "returns the path of the cached gemfile for a digest" do
      Spitball::Repo.gemfile('digest').should == Spitball::Repo.bundle_path('digest', 'gemfile')
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
    [Spitball.new('gemfile contents', 'gemlock', :without => "system").digest,
     Spitball.new('gemfile contents 2', 'gemlock', :without => "system").digest,
     Spitball.new('gemfile', 'gemlock', :without => "other_group").digest,
     Spitball.new('gemfile', 'gemlock').digest,
     Spitball.new('gemfile', 'gemlock2').digest
    ].uniq.length.should == 4
  end

  it "provides a hash equal to the digest's hash"do
    spitball = Spitball.new('gemfile contents', 'gemlock contents')
    spitball.hash.should == spitball.digest.hash
  end
end

describe Spitball do
  context "mismatched" do
    before do
      use_success_bundler

      @gemfile = <<-end_gemfile
          source :rubygems
          gem "json_pure"
          gem "somethingelse"
        end_gemfile

      @lockfile = <<-end_lockfile.strip.gsub(/\n[ ]{6}/m, "\n")
        GEM
          remote: http://rubygems.org/
          specs:
            json_pure (1.4.6)

        PLATFORMS
          ruby

        DEPENDENCIES
          json_pure
      end_lockfile

    end

    describe "create_bundle failure" do
      it "should raise on create_bundle" do
        proc { Spitball.new(@gemfile, @lockfile) }.should raise_error
      end
    end
  end
end

describe Bundler::FakeDsl do
  it "should support a single group" do
    gemfile = <<-end_gemfile
        source :rubygems
        gem "json_pure"

        group :development do
          gem 'rails'
          gem 'json_pure'
        end
      end_gemfile

    dsl = Bundler::FakeDsl.new(gemfile)
    dsl.__groups[:development].should == ["rails", "json_pure"]
  end

  it "should support multiple groups in one line" do
    gemfile = <<-end_gemfile
        source :rubygems
        gem "json_pure"

        group :development, :test do
          gem 'rails'
          gem 'json_pure'
        end
      end_gemfile

    dsl = Bundler::FakeDsl.new(gemfile)
    dsl.__groups[:development].should == ["rails", "json_pure"]
    dsl.__groups[:test].should == ["rails", "json_pure"]
  end

  it "should support multiple groups on several lines" do
    gemfile = <<-end_gemfile
        source :rubygems
        gem "json_pure"

        group :development do
          gem 'rails'
        end

        group :test do
          gem 'json_pure'
        end
      end_gemfile

    dsl = Bundler::FakeDsl.new(gemfile)
    dsl.__groups[:development].should == ["rails"]
    dsl.__groups[:test].should == ["json_pure"]
  end
end
