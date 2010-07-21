require 'spec/spec_helper'

describe Spitball do
  it "works" do
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
  describe "make_cache_dir" do
    it "creates the correct cache dir" do
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
end
