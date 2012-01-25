# encoding: utf-8

#--
###############################################################################
#                                                                             #
# Lingo -- A full-featured automatic indexing system                          #
#                                                                             #
# Copyright (C) 2005-2007 John Vorhauer                                       #
# Copyright (C) 2007-2012 John Vorhauer, Jens Wille                           #
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

  class BufferedAttendee < Attendee

    BufferInsert = Struct.new(:position, :object)

    def initialize(config, lingo)
      # In den Buffer werden alle Objekte geschrieben, bis process_buffer? == true ist
      @buffer = []

      # deferred_inserts beeinflussen nicht die Buffer-Größe, sondern werden an einer
      # bestimmten Stelle in den Datenstrom eingefügt
      @deferred_inserts = []

      super
    end

    protected

    def process(obj)
      @buffer.push(obj)
      process_buffer if process_buffer?
    end

    private

    def forward_buffer
      # Aufgeschobene Einfügungen in Buffer kopieren
      @deferred_inserts.sort_by { |ins| ins.position }.each { |ins|
        @buffer.insert(ins.position, ins.object)
      }
      @deferred_inserts.clear

      # Buffer weiterleiten
      @buffer.each { |obj| forward(obj) }
      @buffer.clear
    end

    def process_buffer?
      true
    end

    def process_buffer
      # to be defined by child class
    end

    def deferred_insert(pos, obj)
      @deferred_inserts << BufferInsert.new(pos, obj)
    end

  end

end
