# define a type that always wraps values into string arrays
module ActiveModel
  module Type
    class StringArray < ActiveModel::Type::Value
      def cast(value)
        Array.wrap(value).map(&:to_s)
      end
    end
  end
end

# register it under a name
ActiveModel::Type.register(:string_array, ActiveModel::Type::StringArray)
