# encoding: utf-8

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
