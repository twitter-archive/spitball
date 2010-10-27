module Bundler
  class FakeDsl
    
    def initialize(file)
      @groups = Hash.new{|h, k| h[k] = []}
      instance_eval(file)
    end

    def __groups
      @groups
    end

    def group(name, &blk)
      @current_group = name.to_sym
      instance_eval(&blk)
      @current_group = nil
    end
    alias_method :groups, :group

    def gem(*args)
      @groups[@current_group] << args.first
    end
    
    def method_missing(*args)
    end
  end
end
