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

  class Database

    # Crypter ermöglicht die Ver- und Entschlüsselung von Wörterbüchern

    class Crypter

      HEX_CHARS = '0123456789abcdef'.freeze

      def digest(key)
        Digest::SHA1.hexdigest(key)
      end

      def encode(key, val)
        hex = ''

        crypt(key, val).each_byte { |byte|
          # To get a hex representation for a char we just utilize
          # the quotient and the remainder of division by base 16.
          q, r = byte.divmod(16)
          hex << HEX_CHARS[q] << HEX_CHARS[r]
        }

        [digest(key), hex]
      end

      def decode(key, val)
        str, q, first = '', 0, false

        val.each_byte { |byte|
          byte = byte.chr(ENC)

          # Our hex chars are 2 bytes wide, so we have to keep track
          # of whether it's the first or the second of the two.
          if first = !first
            q = HEX_CHARS.index(byte)
          else
            # Now we got both parts, so let's revert the divmod(16)
            str << q * 16 + HEX_CHARS.index(byte)
          end
        }

        crypt(key, str)
      end

      private

      def crypt(k, v)
        c, y = '', k.codepoints.reverse_each.cycle
        v.each_codepoint { |x| c << (x ^ y.next).chr(ENC) }
        c
      end

    end

  end

end
