require 'active_support/concern'

# NOTE:
# Overwrite `ActiveSupport::Concern` to add output to STDOUT.
module ActiveSupport
  module Concern
    def self.extended(base) #:nodoc:
      base.instance_variable_set(:@_dependencies, [])
      puts "Concern.extended: #{self} extended in #{base}\
        \n=> @_dependencies=#{base.instance_variable_get(:@_dependencies)}\n\n"
    end

    def append_features(base)
      puts "Concern#appended_features: \n#{caller.reject { |e| (e =~ /include|class\:/).nil? }.join("\n")}"
      puts "> Base: #{base}"
      puts "> Receiver (self): #{self}\n\n"

        if base.instance_variable_defined?(:@_dependencies)
          base.instance_variable_get(:@_dependencies) << self
          return false
        else
          return false if base < self
          @_dependencies.each do |dep|
            puts "> Resolving dependecies for #{self}, by including #{dep} into base #{base}"
            base.send(:include, dep)
          end
          super
          base.extend const_get(:ClassMethods) if const_defined?(:ClassMethods)
          base.class_eval(&@_included_block) if instance_variable_defined?(:@_included_block)
        end
    end

    def included(base = nil, &block)
      if base.nil?
        raise MultipleIncludedBlocks if instance_variable_defined?(:@_included_block)

        @_included_block = block
      else
        super
        puts "Concern#included: #{self} included in #{base}\n\n"
      end
    end
  end
end

module A
  extend ActiveSupport::Concern

  def self.append_features(mod)
    super
    puts "A.append_features: mod=#{mod}, self=#{self}\n\n"
  end

  def self.included(mod)
    super
    puts "A.included: #{self} included in #{mod}\n\n"
  end
end

# This is a dependency on module B
module D
  def get_ivar
    puts "> D#get_ivar: '#{ivar}' (self = #{self.class})!"
  end

  def self.append_features(mod)
    super
    puts "D.append_features: mod=#{mod}, self=#{self}\n\n"
  end

  def self.included(mod)
    super
    puts "D.included: #{self} included in #{mod}\n\n"
  end
end

# Notice how module B's dependency on D is resolved by `ActiveSupport::Concern`
module B
  extend ActiveSupport::Concern

  @_dependencies = [D]

  def self.append_features(mod)
    super
    puts "B.append_features: mod=#{mod}, self=#{self}\n\n"
  end

  def self.included(mod)
    super
    puts "B.included: #{self} included in #{mod}\n\n"
  end

  # 2. Since B is included in class C, the included hook is called.
  # `Module#included` hook (from Ruby) is overwritten by the `included` instance
  # method of `ActiveSupport::Concern`.
  #
  # Since the `base` is `nil`, `@included_block` is set to the block passed as
  # an instance variable in `Concern`.
  included(nil) do  # base is set as nil by default
    # the block passed
    puts "This is the included block in module #{self}!"

    # the call to `meaning_of_life_and_the_universe` is evaluated in the context
    # of this block, which is class C (see end of (3) for further details).
    puts "Meaning of life and the universe? => #{meaning_of_life_and_the_universe}\n\n"
  end

  # 3. When a module (B) is included in another (C),
  # `Method#append_features(mod)` is called in module (B),
  # passing it the receiving module (C) in `mod`
  #
  # Therefore, the arg `base` below is C.  Normally, the following
  # method is not defined in B, but having do so for clarity, we have
  # super, which would be `ActiveSupport::Concern#append_features`, which
  # has overwritten `Method#append_features`.
  #
  # `ActiveSupport::Concern#append_features` checks if C has the
  # `@_dependencies` instance variable defined.However, since
  # we did not extend `ActiveSupport::Concern` in class C, it does
  # not have this instance variable set.
  #
  #   # ActiveSupport::Concern
  #   def append_features(base)
  #     if base.instance_variable_defined?(:@_dependencies)
  #       base.instance_variable_get(:@_dependencies) << self
  #       return false
  #     else
  #       return false if base < self
  #       @_dependencies.each { |dep| base.send(:include, dep) }
  #       super
  #       base.extend const_get(:ClassMethods) if const_defined?(:ClassMethods)
  #       base.class_eval(&@_included_block) if instance_variable_defined?(:@_included_block)
  #     end
  #   end
  #
  # Therefore, the else clause in `ActiveSupport::Concern#append_features`
  # is, in effect, triggered.
  #
  # This iterates through each of the modules stored in
  # `@_dependencies` and includes them in class C (base). We can have
  # multiple modules in the `@_dependencies` instance variable, and we have
  # them all included in `base` here, so that if one depends on another,
  # they are all available now in class C.
  #
  # Note, its call to `super`, effectively calling `Method#append_features`.
  #
  # It then extends ClassMethods if they are defined in module B. It
  # finally invokes `class_eval` method on base (class C), passing in the
  # instance variable `@_included_block` if it is defined.

end

class C

  attr_reader :ivar
  def initialize
    @ivar = "I'm instance #{self}"
  end

  class << self
    def meaning_of_life_and_the_universe
      '42'
    end
  end

  include A
  include B         # 1. Since module B extends `ActiveSupport::Concern`, when
                    # it is included into class C, it invokes the extended hook
                    # `ActiveSupport::Concern.extended` with module B as `base`.
                    #
                    # Here, the instance variable `@_dependencies` is set in B
                    # as []

end

puts "C's ancestors: #{C.ancestors[0..3]}"
_c = C.new
puts "Calling C#get_ivar..."
_c.get_ivar

#binding.pry
