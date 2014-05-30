module Bundler
  class FakeDsl

    def initialize(file)
      @groups = Hash.new{|h, k| h[k] = []}
      @gems = []
      instance_eval(file)
    end

    def __groups
      @groups
    end

    def __gems
      @gems
    end

    def __gem_names
      __gems.map(&:first)
    end

    def group(*group_names, &blk)
      group_names.each do |name|
        @current_group = name.to_sym
        instance_eval(&blk)
        @current_group = nil
      end
    end
    alias_method :groups, :group

    def gem(*args)
      @gems << args
      @groups[@current_group] << args.first
    end

    def method_missing(*args)
    end
  end
end
