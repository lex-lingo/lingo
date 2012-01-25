# encoding: utf-8

class Lingo

  module Error

    class LingoError < StandardError; end

    class NoWritableStoreError < LingoError

      attr_reader :file, :path

      def initialize(file, path)
        @file, @path = file, path
      end

      def to_s
        'No writable store found in search path'
      end

    end

    class ConfigError < LingoError

      attr_reader :id

      def initialize(id)
        @id = id
      end

    end

    class ConfigLoadError < ConfigError

      attr_reader :err

      def initialize(err)
        @err = err
      end

      def to_s
        "Error loading config: #{err}"
      end

    end

    class NoDatabaseConfigError < ConfigError

      def to_s
        "No such database `#{id}' defined."
      end

    end

    class InvalidDatabaseConfigError < ConfigError

      def to_s
        "Invalid database configuration `#{id}'."
      end

    end

    class SourceError < LingoError; end

    class NoSourceFileError < SourceError

      attr_reader :name, :id

      def initialize(name, id)
        @name, @id = name, id
      end

      def to_s
        "No such source file `#{name}' for `#{id}'."
      end

    end

  end

end
