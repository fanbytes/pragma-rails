module Pragma
  module Rails
    # Exposes CRUD operations on a resource through a Rails controller.
    #
    # @author Alessandro Desantis
    module ResourceController
      def self.included(klass)
        klass.extend ClassMethods
        klass.include InstanceMethods
      end

      module ClassMethods # :nodoc:
        # Returns the expected class of the provided operation on this resource.
        #
        # Note that this does not mean the operation is actually supported. Use {#operation?} for
        # that.
        #
        # @param operation_name [Symbol] name of the operation
        #
        # @return [String]
        #
        # @see #operation?
        #
        # @example
        #   API::V1::PostsController.operation_klass(:create) => 'API::V1::Post::Operation::Create'
        def operation_klass(operation_name)
          [self.class.name.deconstantize].tap do |klass|
            klass << self.class.name.demodulize.chomp('Controller').singularize
            klass << "Operation::#{action_name.camelize}"
          end.join('::')
        end

        # Returns whether the provided operation is supported on this resource.
        #
        # @param operation_name [Symbol] name of the operation
        #
        # @return [Boolean]
        def operation?(operation_name)
          class_exists? operation_klass(operation_name)
        end

        private

        def class_exists?(klass)
          Object.const_get(klass)
          true
        rescue NameError
          false
        end
      end

      module InstanceMethods # :nodoc:
        # If an action that does not exist is called on this controller, tries to find and run
        # an operation on the current resource with the same name.
        #
        # For instance, +API::V1::PostsController#create+ would try to find and run
        # +API::V1::Post::Operation::Create+.
        #
        # @param action_name [String] name of the missing action
        def action_missing(action_name)
          send(action_name)
        end

        # Supports running missing actions.
        #
        # @see #action_missing
        def method_missing(method_name, *arguments, &block)
          return super unless self.class.operation?(method_name)
          run self.class.operation_klass(method_name)
        end

        # Supports running missing actions.
        #
        # @see #action_missing
        def respond_to_missing?(method_name, include_private = false)
          self.class.operation?(method_name) || super
        end
      end
    end
  end
end
