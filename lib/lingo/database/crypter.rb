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

require 'openssl'
require 'digest/sha1'

class Lingo

  class Database

    # Crypter ermöglicht die Ver- und Entschlüsselung von Wörterbüchern

    class Crypter

      def digest(key)
        Digest::SHA1.hexdigest(key)
      end

      def encode(key, val)
        [digest(key), crypt(:encrypt, key, val)]
      end

      def decode(key, val)
        crypt(:decrypt, key, val).force_encoding(ENC)
      end

      private

      def crypt(method, key, val)
        cipher = OpenSSL::Cipher.new('aes-128-cbc').send(method)
        cipher.iv = cipher.key = digest(key)
        cipher.update(val) + cipher.final
      end

    end

  end

end
