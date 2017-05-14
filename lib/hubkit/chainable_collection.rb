# A class which wraps an array (or Enumerable) and provides convenience
# methods for chainable filters, e.g.:
#     repo.issues.unassigned.labeled('in progress')
module Hubkit
  class ChainableCollection
    def self.scope(name, &block)
      define_method name do |*args|
        wrap(
          instance_exec(*args, &block),
        )
      end
    end

    def initialize(inner)
      @inner = inner
    end

    def select(&block)
      return wrap(@inner.select &block) if block_given?
      wrap(@inner.select)
    end

    def wrap(items)
      self.class.new(items)
    end

    def respond_to?(name, include_all = false)
      super || @inner.respond_to?(name)
    end

    def method_missing(name, *args, &block)
      return super unless @inner.respond_to?(name)
      @inner.send(name, *args, &block)
    end

    def not
      NotCollection.new(self)
    end

    def ==(other)
      other == self.to_a
    end
  end

  # A collection that lets you perform the inverse of a filter, e.g.
  #     repo.issues.not.labeled('in progress')
  class NotCollection
    def initialize(base)
      @base = base
    end

    def method_missing(name, *args, &block)
      @base.wrap(@base - @base.send(name, *args, &block))
    end
  end
end
