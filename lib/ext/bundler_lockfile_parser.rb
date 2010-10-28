require "strscan"

module Bundler
  class FakeLockfileParser
    attr_reader :sources, :dependencies, :specs, :platforms

    def initialize(lockfile)
      @platforms    = []
      @sources      = []
      @dependencies = []
      @specs        = []
      @state        = :source

      lockfile.split(/(\r?\n)+/).each do |line|
        if line == "DEPENDENCIES"
          @state = :dependency
        elsif line == "PLATFORMS"
          @state = :platform
        else
          send("parse_#{@state}", line)
        end
      end
    end

  private

    TYPES = {
      "GIT"  => 'git',
      "GEM"  => 'gem',
      "PATH" => 'path'
    }

    GemSource = Struct.new(:remotes)

    def parse_source(line)
      case line
      when "GIT", "GEM", "PATH"
        @current_source = nil
        @opts, @type = {}, line
      when "  specs:"
        case @type
        when 'GEM'
          @current_source = GemSource.new([])
          @current_source.remotes << @opts['remote']
        else
          raise
        end
        @sources << @current_source
      when /^  ([a-z]+): (.*)$/i
        value = $2
        value = true if value == "true"
        value = false if value == "false"

        key = $1

        if @opts[key]
          @opts[key] = Array(@opts[key])
          @opts[key] << value
        else
          @opts[key] = value
        end
      else
        parse_spec(line)
      end
    end

    NAME_VERSION = '(?! )(.*?)(?: \(([^-]*)(?:-(.*))?\))?'

    def parse_dependency(line)
      if line =~ %r{^ {2}#{NAME_VERSION}(!)?$}
        name, version, pinned = $1, $2, $4
        version = version.split(",").map { |d| d.strip } if version

        dep = Gem::Dependency.new(name, version)

        if pinned && dep.name != 'bundler'
          spec = @specs.find { |s| s.name == dep.name }
          dep.source = spec.source if spec
        end

        @dependencies << dep
      end
    end

    def parse_spec(line)
      if line =~ %r{^ {4}#{NAME_VERSION}$}
        name, version = $1, Gem::Version.new($2)
        platform = $3 ? Gem::Platform.new($3) : Gem::Platform::RUBY
        @current_spec = Gem::Specification.new
        @current_spec.name = name
        @current_spec.version = version
        #@current_spec.source = @current_source
        @specs << @current_spec
      elsif line =~ %r{^ {6}#{NAME_VERSION}$}
        name, version = $1, $2
        version = version.split(',').map { |d| d.strip } if version
        dep = Gem::Dependency.new(name, version)
        @current_spec.dependencies << dep
      end
    end

    def parse_platform(line)
      if line =~ /^  (.*)$/
        @platforms << Gem::Platform.new($1)
      end
    end

  end
end
