# encoding: utf-8

#  LINGO ist ein Indexierungssystem mit Grundformreduktion, Kompositumzerlegung,
#  Mehrworterkennung und Relationierung.
#
#  Copyright (C) 2005-2007 John Vorhauer
#  Copyright (C) 2007-2011 John Vorhauer, Jens Wille
#
#  This program is free software; you can redistribute it and/or modify it under
#  the terms of the GNU Affero General Public License as published by the Free
#  Software Foundation; either version 3 of the License, or (at your option)
#  any later version.
#
#  This program is distributed in the hope that it will be useful, but WITHOUT
#  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
#  FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
#  details.
#
#  You should have received a copy of the GNU Affero General Public License along
#  with this program; if not, write to the Free Software Foundation, Inc.,
#  51 Franklin St, Fifth Floor, Boston, MA 02110, USA
#
#  For more information visit http://www.lex-lingo.de or contact me at
#  welcomeATlex-lingoDOTde near 50°55'N+6°55'E.
#
#  Lex Lingo rules from here on

class Lingo

ENC = 'UTF-8'

STRING_SEPERATOR_PATTERN = /[; ,\|]/
FILE_EXTENSION_PATTERN   = /(\.[^.]+)$/

#    String-Konstanten im Datenstrom
CHAR_PUNCT = '.'

#    Define printable characters for tokenizer for UTF-8 encoding
UTF_8_DIGIT  = '[0-9]'
#    Define Basic Latin printable characters for UTF-8 encoding from U+0000 to U+007f
UTF_8_BASLAT = '[A-Za-z]'
#    Define Latin-1 Supplement printable characters for UTF-8 encoding from U+0080 to U+00ff
UTF_8_LAT1SP = '[\xc3\x80-\xc3\x96\xc3\x98-\xc3\xb6\xc3\xb8-\xc3\xbf]'
#    Define Latin Extended-A printable characters for UTF-8 encoding from U+0100 to U+017f
UTF_8_LATEXA = '[\xc4\x80-\xc4\xbf\xc5\x80-\xc5\xbf]'
#    Define Latin Extended-B printable characters for UTF-8 encoding from U+0180 to U+024f
UTF_8_LATEXB = '[\xc6\x80-\xc6\xbf\xc7\x80-\xc7\xbf\xc8\x80-\xc8\xbf\xc9\x80-\xc9\x8f]'
#    Define IPA Extension printable characters for UTF-8 encoding from U+024f to U+02af
UTF_8_IPAEXT = '[\xc9\xa0-\xc9\xbf\xca\xa0-\xca\xaf]'
#    Collect all UTF-8 printable characters in Unicode range U+0000 to U+02af
UTF_8_CHAR   = "#{UTF_8_DIGIT}|#{UTF_8_BASLAT}|#{UTF_8_LAT1SP}|#{UTF_8_LATEXA}|#{UTF_8_LATEXB}|#{UTF_8_IPAEXT}"

PRINTABLE_CHAR = "#{UTF_8_CHAR}|[<>-]"

#    status vars
STA_FORMAT_INT   = '  %-20s = %d'
STA_FORMAT_FLT   = '  %-20s = %6.5f'
STA_NUM_COMMANDS = 'Received Commands'
STA_NUM_OBJECTS  = 'Received Objects '
STA_TIM_COMMANDS = 'Time to control  '
STA_TIM_OBJECTS  = 'Time to process  '
STA_PER_OBJECT   = 'Time per object  '
STA_PER_COMMAND  = 'Time per command '

#    stream commands
STR_CMD_TALK   = 'TALK'
STR_CMD_STATUS = 'STATUS'
STR_CMD_ERR    = 'ERR'
STR_CMD_WARN   = 'WARN'
STR_CMD_LIR    = 'LIR-FORMAT'
STR_CMD_FILE   = 'FILE'
STR_CMD_EOL    = 'EOL'
STR_CMD_RECORD = 'RECORD'
STR_CMD_EOF    = 'EOF'

#    token attributes
TA_WORD         = 'WORD'
TA_PUNCTUATION  = 'PUNC'
TA_NUMERICAL    = 'NUMS'
TA_URL          = 'URLS'
TA_ABREVIATION  = 'ABRV'
TA_ABREVIATION1 = 'ABRS'
TA_OTHER        = 'OTHR'
TA_STOPWORD     = 'STOP'



#    word attributes
WA_UNSET      = '-'    # Standardattribut bei der Initialisierung eines Word-Objektes
WA_IDENTIFIED = 'IDF'  # Status, nachdem das Word im Wörterbuch gefunden wurde
WA_UNKNOWN    = '?'    # Status, wenn das Word nicht gefunden werden konnte
WA_KOMPOSITUM = 'KOM'  # Wort ist als Kompositum erkannt worden
WA_MULTIWORD  = 'MUL'  # Wort ist eine Mehrwortgruppe
WA_SEQUENCE   = 'SEQ'  # Wort ist eine Mehrwortgruppe
WA_UNKMULPART = 'MU?'  # Word ist unbekannt, jedoch Teil einer Mehrwortgruppe

#    lexical attributes ( Wortklassen )
LA_SUBSTANTIV = 's'
LA_ADJEKTIV   = 'a'
LA_VERB       = 'v'
LA_EIGENNAME  = 'e'
LA_KOMPOSITUM = 'k'
LA_MULTIWORD  = 'm'
LA_SEQUENCE   = 'q'
LA_WORTFORM   = 'w'
LA_SYNONYM    = 'y'
LA_STOPWORD   = 't'
LA_TAKEITASIS = 'x'
LA_UNKNOWN    = '?'

LA_SORTORDER = [
  LA_MULTIWORD,
  LA_KOMPOSITUM,
  LA_SUBSTANTIV,
  LA_VERB,
  LA_ADJEKTIV,
  LA_EIGENNAME,
  LA_WORTFORM,
  LA_STOPWORD,
  LA_TAKEITASIS,
  LA_SYNONYM,
  LA_UNKNOWN
].reverse.join

#    field seperator for dbm files
KEY_SEP = '='
FLD_SEP = '|'
IDX_REF = '^'
KEY_REF = '*'
SYS_KEY = '~'

end
