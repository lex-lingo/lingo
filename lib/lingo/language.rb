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

require_relative 'language/lexical_hash'
require_relative 'language/dictionary'
require_relative 'language/grammar'
require_relative 'language/word_form'
require_relative 'language/token'
require_relative 'language/lexical'
require_relative 'language/word'

class Lingo

  module Language

    # String-Konstanten im Datenstrom
    CHAR_PUNCT = '.'

    TA_WORD        = 'WORD'
    TA_PUNCTUATION = 'PUNC'
    TA_OTHER       = 'OTHR'

    # Standardattribut bei der Initialisierung eines Word-Objektes
    WA_UNSET      = '-'
    # Status, nachdem das Word im Wörterbuch gefunden wurde
    WA_IDENTIFIED = 'IDF'
    # Status, wenn das Word nicht gefunden werden konnte
    WA_UNKNOWN    = '?'
    # Wort ist als Kompositum erkannt worden
    WA_COMPOUND   = 'KOM'
    # Wort ist eine Mehrwortgruppe
    WA_MULTIWORD  = 'MUL'
    # Wort ist eine Mehrwortgruppe
    WA_SEQUENCE   = 'SEQ'
    # Word ist unbekannt, jedoch Teil einer Mehrwortgruppe
    WA_UNKMULPART = 'MU?'

    LA_SORTORDER = [
      LA_SEQUENCE   = 'q',
      LA_MULTIWORD  = 'm',
      LA_COMPOUND   = 'k',
      LA_NOUN       = 's',
      LA_VERB       = 'v',
      LA_ADJECTIVE  = 'a',
      LA_NAME       = 'e',
      LA_WORDFORM   = 'w',
      LA_STOPWORD   = 't',
      LA_TAKEITASIS = 'x',
      LA_SYNONYM    = 'y',
      LA_UNKNOWN    = '?'
    ].reverse.join

  end

end
