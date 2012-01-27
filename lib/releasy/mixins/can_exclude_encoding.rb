module Releasy
  module Mixins
    module CanExcludeEncoding
      # Exclude unnecessary encoding files, only keeping those that sufficient for basic use of Ruby.
      def exclude_encoding
        @encoding_excluded = true
      end

      protected
      # Has encoding been excluded from builds?
      def encoding_excluded?
        @encoding_excluded ||= false

        if is_a? Project
          @encoding_excluded
        else
          @encoding_excluded || project.send(:encoding_excluded?)
        end
      end
    end
  end
end