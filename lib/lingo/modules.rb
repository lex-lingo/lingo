# encoding: utf-8

#--
# LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung,
# Mehrworterkennung und Relationierung.
#
# Copyright (C) 2005-2007 John Vorhauer
# Copyright (C) 2007-2012 John Vorhauer, Jens Wille
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation; either version 3 of the License, or (at your option)
# any later version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin St, Fifth Floor, Boston, MA 02110, USA
#
# For more information visit http://www.lex-lingo.de or contact me at
# welcomeATlex-lingoDOTde near 50°55'N+6°55'E.
#
# Lex Lingo rules from here on
#++

class Lingo

  # Provides counters.

  module Reportable

    def init_reportable(prefix = nil)
      @counters, @prefix = Hash.new(0), prefix ? "#{prefix}: " : ''
    end

    def inc(counter)
      @counters[counter] += 1
    end

    def add(counter, value)
      @counters[counter] += value
    end

    def set(counter, value)
      @counters[counter] = value
    end

    def get(counter)
      @counters[counter]
    end

    def report
      @counters.each_with_object({}) { |(k, v), r| r["#{@prefix}#{k}"] = v }
    end

  end

  # Provides a simple caching mechanism.

  module Cachable

    def init_cachable
      @cache = Hash.new(false)
    end

    def hit?(key)
      @cache.has_key?(key)
    end

    def store(key, value)
      @cache[key] = cache_value(value)
      value
    end

    def retrieve(key)
      cache_value(@cache[key])
    end

    private

    def cache_value(value)
      value.nil? ? nil : value.dup
    end

  end

end
