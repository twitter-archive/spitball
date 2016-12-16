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
      expect(@spitball).not_to be_cached
      expect(@spitball).to receive(:get_specs).and_return([])
      @spitball.cache!
      expect(@spitball).to be_cached
    end
  end

  describe "cache!" do
    it "returns if the spitball is cached" do
      expect(@spitball).to receive(:cached?).and_return(true)
      expect(Spitball::FileLock).not_to receive(:acuire_lock)
      expect(Spitball::FileLock).not_to receive(:release_lock)
      expect(@spitball).not_to receive(:create_bundle)
      @spitball.cache!
    end

    it "creates the bundle if it acquires the lock" do
      file_lock = instance_double("Spitball::FileLock")

      expect(@spitball).to receive(:cached?).and_return(false).twice
      expect(@spitball).to receive(:get_file_lock).and_return(file_lock)
      expect(file_lock).to receive(:acquire_lock).and_return(true)
      expect(@spitball).to receive(:create_bundle)
      expect(file_lock).to receive(:release_lock)
      @spitball.cache!
    end

    it "does not create the bundle if it does not acquire the lock" do
      file_lock = instance_double("Spitball::FileLock")
      expect(@spitball).to receive(:get_file_lock).and_return(file_lock)
      expect(file_lock).to receive(:acquire_lock).and_return(false)
      expect(file_lock).not_to receive(:release_lock)
      expect(@spitball).not_to receive(:create_bundle)
      @spitball.cache!(false)
    end

    it "blocks if it does not acquire the lock and sync is true (default)" do
      cached = false
      done_caching = false

      file_lock = instance_double("Spitball::FileLock")
      expect(@spitball).to receive(:get_file_lock).and_return(file_lock).at_most(3).times
      expect(@spitball).to receive(:cached?).and_return(false).at_most(2).times
      expect(@spitball).to receive(:cached?).and_return(true)
      expect(file_lock).to receive(:acquire_lock).and_return(false).at_most(2).times

      t = Thread.new do
        @spitball.cache!
        done_caching = true
      end

      sleep 0.1
      expect(done_caching).to be false

      cached = true
      t.join
      expect(done_caching).to be true
    end
  end

  describe "generate_build_args" do
    it "returns an empty string for nil" do
      expect(@spitball.send(:generate_build_args, nil)).to eq('')
    end

    it "returns arguments prepended with double dashes for a string" do
      expect(@spitball.send(:generate_build_args, '--build-args=joesmith')).to eq('-- --build-args=joesmith')
    end
  end

  describe "create_bundle" do
    it "generates a bundle at the bundle_path" do
      expect(@spitball).to receive(:get_specs).and_return([])
      capture_stdout { @spitball.send :create_bundle }
      expect(File.exist?(@spitball.send(:tarball_path))).to be true
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

      expect(@spitball).to receive(:install_and_copy_spec).exactly(8).times

      @spitball.send :create_bundle
      @spitball = Spitball.new(@gemfile, @lockfile, :without => 'development')

      expect(@spitball).to receive(:install_and_copy_spec).exactly(1).times
      @spitball.send :create_bundle
    end
  end

  context "sources_opt" do
    it "does not add --clear sources for rubygems >= 1.4.0" do
      @spitball = Spitball.new(@gemfile, @lockfile)
      parsed_lockfile =  @spitball.instance_variable_get("@parsed_lockfile")
      stub_const("Gem::VERSION", "1.3.10")
      expect(@spitball.send(:sources_opt, parsed_lockfile.sources)).to eq("--source http://rubygems.org/")
    end

    it "adds --clear sources for rubygems >= 1.4.0" do
      @spitball = Spitball.new(@gemfile, @lockfile)
      parsed_lockfile =  @spitball.instance_variable_get("@parsed_lockfile")
      stub_const("Gem::VERSION", "1.4.0")
      expect(@spitball.send(:sources_opt, parsed_lockfile.sources)).to eq("--clear-sources --source http://rubygems.org/")
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
      expect(@lock.acquire_lock).to be true
    end

    it "returns false if the lock is not acquired" do
      fork { @lock.acquire_lock; exit! }
      Process.wait

      expect(@lock.acquire_lock).to be false
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

      expect(File.exist?(SPITBALL_CACHE)).to be false
      Spitball::Repo.make_cache_dirs
      expect(File.exist?(SPITBALL_CACHE)).to be true
    end
  end

  describe "bundle_path" do
    it "generates paths with the correct cache" do
      expect(Spitball::Repo.bundle_path('digest')).to match /^#{SPITBALL_CACHE}/
    end

    it "generates paths with extensions" do
      expect(Spitball::Repo.bundle_path('digest', 'tgz')).to match /\.tgz$/
    end

    it "generates paths prefixed with bundle_" do
      expect(Spitball::Repo.bundle_path('digest', 'tgz')).to match /bundle_digest\.tgz$/
    end
  end

  describe "gemcache_path" do
    it "returns the correct path in the cache dir" do
      expect(Spitball::Repo.gemcache_path).to eq(File.join(SPITBALL_CACHE, "gemcache"))
    end
  end

  describe "exist?" do
    it "returns true if tarball for a digest exists" do
      expect(Spitball::Repo.exist?('digest')).to be false
      File.open(Spitball::Repo.bundle_path('digest', 'tgz'), 'w') {|f| f.write 'tarball!' }
      expect(Spitball::Repo.exist?('digest')).to be true
    end
  end

  describe "tarball" do
    it "returns the path of the cached tarball for a digest" do
      expect(Spitball::Repo.tarball('digest')).to eq(Spitball::Repo.bundle_path('digest', 'tgz'))
    end
  end

  describe "gemfile" do
    it "returns the path of the cached gemfile for a digest" do
      expect(Spitball::Repo.gemfile('digest')).to eq(
        Spitball::Repo.bundle_path('digest', 'gemfile'))
    end
  end

  describe "cached_digests" do
    it "returns a list of cached bundles" do
      File.open(Spitball::Repo.tarball('digest'), 'w') {|f| f.write 'tarball!' }
      File.open(Spitball::Repo.tarball('digest2'), 'w') {|f| f.write 'tarball2!' }

      expect(Spitball::Repo.cached_digests).to eq(['digest', 'digest2'])
    end
  end

  describe "clean_up_unused" do
    it "removes cached tarballs and gemfiles that haven't been accessed within a certain period" do
      File.open(Spitball::Repo.tarball('digest'), 'w') {|f| f.write 'tarball!' }
      File.open(Spitball::Repo.gemfile('digest'), 'w') {|f| f.write 'gemfile!' }

      sleep 3
      File.open(Spitball::Repo.tarball('digest2'), 'w') {|f| f.write 'tarball2!' }
      File.open(Spitball::Repo.gemfile('digest2'), 'w') {|f| f.write 'gemfile2!' }

      Spitball::Repo.clean_up_unused(1)

      expect(File.exist?(Spitball::Repo.tarball('digest'))).to be false
      expect(File.exist?(Spitball::Repo.gemfile('digest'))).to be false
      expect(File.exist?(Spitball::Repo.tarball('digest2'))).to be true
      expect(File.exist?(Spitball::Repo.gemfile('digest2'))).to be true
    end
  end
end

describe Spitball::Digest do
  it "generates a digest based on the spitball's options and gemfile" do
    expect([
      Spitball.new('gemfile contents', 'gemlock', :without => "system").digest,
      Spitball.new('gemfile contents 2', 'gemlock', :without => "system").digest,
      Spitball.new('gemfile', 'gemlock', :without => "other_group").digest,
      Spitball.new('gemfile', 'gemlock').digest,
      Spitball.new('gemfile', 'gemlock2').digest
    ].uniq.length).to eq(4)
  end

  it "provides a hash equal to the digest's hash"do
    spitball = Spitball.new('gemfile contents', 'gemlock contents')
    expect(spitball.hash).to eq(spitball.digest.hash)
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
        expect {
          Spitball.new(@gemfile, @lockfile)
        }.to raise_error(StandardError)
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
    expect(dsl.__groups[:development]).to eq(["rails", "json_pure"])
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
    expect(dsl.__groups[:development]).to eq(["rails", "json_pure"])
    expect(dsl.__groups[:test]).to eq(["rails", "json_pure"])
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
    expect(dsl.__groups[:development]).to eq(["rails"])
    expect(dsl.__groups[:test]).to eq(["json_pure"])
  end
end
