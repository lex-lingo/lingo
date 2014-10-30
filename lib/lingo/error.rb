# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2014 John Vorhauer, Jens Wille                           #
#                                                                             #
# Lingo is free software; you can redistribute it and/or modify it under the  #
# terms of the GNU Affero General Public License as published by the Free     #
# Software Foundation; either version 3 of the License, or (at your option)   #
# any later version.                                                          #
#                                                                             #
# Lingo is distributed in the hope that it will be useful, but WITHOUT ANY    #
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS   #
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for     #
# more details.                                                               #
#                                                                             #
# You should have received a copy of the GNU Affero General Public License    #
# along with Lingo. If not, see <http://www.gnu.org/licenses/>.               #
#                                                                             #
###############################################################################
#++

class Lingo

  class LingoError < StandardError

    def class_name
      klass.name.split('::').last
    end

    def error(msg = 'An error occurred')
      "#{msg}: #{err} (#{err.class})"
    end

  end

  class NoWritableStoreError < LingoError

    attr_reader :file, :path

    def initialize(file, path)
      @file, @path = file, path
    end

    def to_s
      'No writable store found in search path.'
    end

  end

  class BackendNotFoundError < LingoError

    attr_reader :file

    def initialize(file)
      @file = file
    end

    def to_s
      "No backend found for `#{file}'."
    end

  end

  class BackendNotAvailableError < LingoError

    attr_reader :mod, :file

    def initialize(mod, file)
      @mod, @file = mod, file
    end

    def to_s
      "Backend not available `#{mod}' for `#{file}'."
    end

  end

  class DatabaseError < LingoError

    attr_reader :action, :file, :err

    def initialize(action, file, err)
      @action, @file, @err = action, file, err
    end

    def to_s
      error("An error occured while trying to #{action} `#{file}'")
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
      error("Error loading config")
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

  class MissingConfigError < ConfigError

    def to_s
      "Missing configuration for `#{id}'."
    end

  end

  class FileNotFoundError < LingoError

    attr_reader :name

    def initialize(name)
      @name = name
    end

    def to_s
      "No such file `#{name}'."
    end

  end

  class SourceFileNotFoundError < FileNotFoundError

    attr_reader :id

    def initialize(name, id)
      super(name)
      @id = id
    end

    def to_s
      "No such source file `#{name}' for `#{id}'."
    end

  end

  class NameNotFoundError < LingoError

    attr_reader :klass, :name

    def initialize(klass, name)
      @klass, @name = klass, name
    end

    def to_s
      "No such #{class_name} type `#{name}'."
    end

  end

  class LibraryLoadError < LingoError

    attr_reader :klass, :lib, :err

    def initialize(klass, lib, err)
      @klass, @lib, @err = klass, lib, err
    end

    def to_s
      error("#{class_name}: An error occured while trying to load `#{lib}'")
    end

  end

  class TokenizeError < LingoError

    attr_reader :line, :file, :num, :err

    def initialize(line, file, num, err)
      @line, @file, @num, @err = line, file, num, err
    end

    def to_s
      line, file = self.line, self.file

      if line.is_a?(String) && line.length > 48
        line = line[0, 45] + '...'
      end

      file &&= "#{file}:#{num}: "

      error("An error occured while trying to tokenize #{file}#{line.inspect}")
    end

  end

end
