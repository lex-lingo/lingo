# encoding: utf-8

require_relative '../test_helper'

class TestAttendeeSequencer < AttendeeTestCase

  def setup
    @perm = [
      wd('white|IDF', 'white|s', 'white|a', 'white|v'),
      wd('yellow|IDF', 'yellow|s', 'yellow|a', 'yellow|v'),
      wd('green|IDF', 'green|s', 'green|a', 'green|v'),
      wd('white|IDF', 'white|s', 'white|a', 'white|v'),
      wd('cold|IDF', 'cold|s', 'cold|a'),
      wd('hot|IDF', 'hot|a'),
      wd('hot|IDF', 'hot|a'),
      wd('water|IDF', 'water|s', 'water|v'),
      wd('warm|IDF', 'warm|a', 'warm|v'),
      wd('warm|IDF', 'warm|a', 'warm|v'),
      wd('dry|IDF', 'dry|s', 'dry|a', 'dry|v'),
      wd('weather|IDF', 'weather|s', 'weather|v'),
      wd('drink|IDF', 'drink|s', 'drink|v'),
      wd('winter|IDF', 'winter|s', 'winter|v'),
      wd('cool|IDF', 'cool|s', 'cool|a', 'cool|v'),
      wd('fruit|IDF', 'fruit|s', 'fruit|v'),
      wd('vegetable|IDF', 'vegetable|s', 'vegetable|a'),
      wd('food|IDF', 'food|s'),
      wd('juice|IDF', 'juice|s', 'juice|v'),
      wd('flower|IDF', 'flower|s', 'flower|v'),
      wd('fresh|IDF', 'fresh|s', 'fresh|a'),
      wd('fish|IDF', 'fish|s', 'fish|a', 'fish|v'),
      wd('tree|IDF', 'tree|s', 'tree|v'),
      wd('meat|IDF', 'meat|s'),
      wd('salad|IDF', 'salad|s'),
      wd('vegetable|IDF', 'vegetable|s', 'vegetable|a'),
      wd('green|IDF', 'green|s', 'green|a', 'green|v'),
      wd('red|IDF', 'red|s', 'red|a', 'red|v'),
      wd('red|IDF', 'red|s', 'red|a', 'red|v'),
      wd('blue|IDF', 'blue|s', 'blue|a', 'blue|v'),
      wd('blue|IDF', 'blue|s', 'blue|a', 'blue|v'),
      wd('yellow|IDF', 'yellow|s', 'yellow|a', 'yellow|v'),
      wd('white|IDF', 'white|s', 'white|a', 'white|v'),
      wd('leaves|IDF', 'leave|s', 'leaf|s', 'leave|v'),
      wd('yellow|IDF', 'yellow|s', 'yellow|a', 'yellow|v'),
      wd('colour|IDF', 'colour|s', 'colour|v'),
      wd('grey|IDF', 'grey|s'),
      wd('tobacco|IDF', 'tobacco|s'),
      wd('advertising|IDF', 'advertising|e'),
      wd('cigarette|IDF', 'cigarette|s'),
      wd('smoke|IDF', 'smoke|s', 'smoke|v'),
      wd('alcohol|IDF', 'alcohol|s'),
      wd('ban|IDF', 'ban|s'),
      wd('coal|IDF', 'coal|s'),
      wd('cigarette|IDF', 'cigarette|s'),
      wd('import|IDF', 'import|s', 'import|v'),
      wd('alcohol|IDF', 'alcohol|s'),
      wd('textile|IDF', 'textile|s'),
      wd('whiskey|IDF', 'whiskey|s'),
      wd('drink|IDF', 'drink|s', 'drink|v'),
      wd('whisky|IDF', 'whisky|s'),
      ai('EOF|'),
      ai('EOT|')
    ]

    @out1 = [
      wd('white|IDF', 'white|s', 'white|a', 'white|v'),
      wd('yellow|IDF', 'yellow|s', 'yellow|a', 'yellow|v'),
      wd('green|IDF', 'green|s', 'green|a', 'green|v'),
      wd('white|IDF', 'white|s', 'white|a', 'white|v'),
      wd('cold|IDF', 'cold|s', 'cold|a'),
      wd('hot|IDF', 'hot|a'),
      wd('hot|IDF', 'hot|a'),
      wd('water|IDF', 'water|s', 'water|v'),
      wd('warm|IDF', 'warm|a', 'warm|v'),
      wd('warm|IDF', 'warm|a', 'warm|v'),
      wd('dry|IDF', 'dry|s', 'dry|a', 'dry|v'),
      wd('weather|IDF', 'weather|s', 'weather|v'),
      wd('drink|IDF', 'drink|s', 'drink|v'),
      wd('winter|IDF', 'winter|s', 'winter|v'),
      wd('cool|IDF', 'cool|s', 'cool|a', 'cool|v'),
      wd('fruit|IDF', 'fruit|s', 'fruit|v'),
      wd('vegetable|IDF', 'vegetable|s', 'vegetable|a'),
      wd('food|IDF', 'food|s'),
      wd('juice|IDF', 'juice|s', 'juice|v'),
      wd('flower|IDF', 'flower|s', 'flower|v'),
      wd('fresh|IDF', 'fresh|s', 'fresh|a'),
      wd('fish|IDF', 'fish|s', 'fish|a', 'fish|v'),
      wd('tree|IDF', 'tree|s', 'tree|v'),
      wd('meat|IDF', 'meat|s'),
      wd('salad|IDF', 'salad|s'),
      wd('vegetable|IDF', 'vegetable|s', 'vegetable|a'),
      wd('green|IDF', 'green|s', 'green|a', 'green|v'),
      wd('red|IDF', 'red|s', 'red|a', 'red|v'),
      wd('red|IDF', 'red|s', 'red|a', 'red|v'),
      wd('blue|IDF', 'blue|s', 'blue|a', 'blue|v'),
      wd('blue|IDF', 'blue|s', 'blue|a', 'blue|v'),
      wd('yellow|IDF', 'yellow|s', 'yellow|a', 'yellow|v'),
      wd('white|IDF', 'white|s', 'white|a', 'white|v'),
      wd('leaves|IDF', 'leave|s', 'leaf|s', 'leave|v'),
      wd('yellow|IDF', 'yellow|s', 'yellow|a', 'yellow|v'),
      wd('colour|IDF', 'colour|s', 'colour|v'),
      wd('grey|IDF', 'grey|s'),
      wd('tobacco|IDF', 'tobacco|s'),
      wd('advertising|IDF', 'advertising|e'),
      wd('cigarette|IDF', 'cigarette|s'),
      wd('smoke|IDF', 'smoke|s', 'smoke|v'),
      wd('alcohol|IDF', 'alcohol|s'),
      wd('ban|IDF', 'ban|s'),
      wd('coal|IDF', 'coal|s'),
      wd('cigarette|IDF', 'cigarette|s'),
      wd('import|IDF', 'import|s', 'import|v'),
      wd('alcohol|IDF', 'alcohol|s'),
      wd('textile|IDF', 'textile|s'),
      wd('whiskey|IDF', 'whiskey|s'),
      wd('drink|IDF', 'drink|s', 'drink|v'),
      wd('whisky|IDF', 'whisky|s'),
      wd('white yellow|SEQ', 'yellow, white|q'),
      wd('yellow green|SEQ', 'green, yellow|q'),
      wd('green white|SEQ', 'white, green|q'),
      wd('white cold|SEQ', 'cold, white|q'),
      wd('hot water|SEQ', 'water, hot|q'),
      wd('warm dry|SEQ', 'dry, warm|q'),
      wd('dry weather|SEQ', 'weather, dry|q'),
      wd('cool fruit|SEQ', 'fruit, cool|q'),
      wd('vegetable food|SEQ', 'food, vegetable|q'),
      wd('fresh fish|SEQ', 'fish, fresh|q'),
      wd('fish tree|SEQ', 'tree, fish|q'),
      wd('vegetable green|SEQ', 'green, vegetable|q'),
      wd('green red|SEQ', 'red, green|q'),
      wd('red red|SEQ', 'red, red|q'),
      wd('red blue|SEQ', 'blue, red|q'),
      wd('blue blue|SEQ', 'blue, blue|q'),
      wd('blue yellow|SEQ', 'yellow, blue|q'),
      wd('yellow white|SEQ', 'white, yellow|q'),
      wd('white leaves|SEQ', 'leave, white|q'),
      wd('yellow colour|SEQ', 'colour, yellow|q'),
      wd('white yellow green|SEQ', 'green, white yellow|q'),
      wd('yellow green white|SEQ', 'white, yellow green|q'),
      wd('green white cold|SEQ', 'cold, green white|q'),
      wd('hot hot water|SEQ', 'water, hot hot|q'),
      wd('warm warm dry|SEQ', 'dry, warm warm|q'),
      wd('warm dry weather|SEQ', 'weather, warm dry|q'),
      wd('fresh fish tree|SEQ', 'tree, fresh fish|q'),
      wd('vegetable green red|SEQ', 'red, vegetable green|q'),
      wd('green red red|SEQ', 'red, green red|q'),
      wd('red red blue|SEQ', 'blue, red red|q'),
      wd('red blue blue|SEQ', 'blue, red blue|q'),
      wd('blue blue yellow|SEQ', 'yellow, blue blue|q'),
      wd('blue yellow white|SEQ', 'white, blue yellow|q'),
      wd('yellow white leaves|SEQ', 'leave, yellow white|q'),
      ai('EOF|'),
      ai('EOT|')
    ]

    @out2 = [
      wd('white|IDF', 'white|s', 'white|a', 'white|v'),
      wd('yellow|IDF', 'yellow|s', 'yellow|a', 'yellow|v'),
      wd('green|IDF', 'green|s', 'green|a', 'green|v'),
      wd('white|IDF', 'white|s', 'white|a', 'white|v'),
      wd('cold|IDF', 'cold|s', 'cold|a'),
      wd('hot|IDF', 'hot|a'),
      wd('hot|IDF', 'hot|a'),
      wd('water|IDF', 'water|s', 'water|v'),
      wd('warm|IDF', 'warm|a', 'warm|v'),
      wd('warm|IDF', 'warm|a', 'warm|v'),
      wd('dry|IDF', 'dry|s', 'dry|a', 'dry|v'),
      wd('weather|IDF', 'weather|s', 'weather|v'),
      wd('drink|IDF', 'drink|s', 'drink|v'),
      wd('winter|IDF', 'winter|s', 'winter|v'),
      wd('cool|IDF', 'cool|s', 'cool|a', 'cool|v'),
      wd('fruit|IDF', 'fruit|s', 'fruit|v'),
      wd('vegetable|IDF', 'vegetable|s', 'vegetable|a'),
      wd('food|IDF', 'food|s'),
      wd('juice|IDF', 'juice|s', 'juice|v'),
      wd('flower|IDF', 'flower|s', 'flower|v'),
      wd('fresh|IDF', 'fresh|s', 'fresh|a'),
      wd('fish|IDF', 'fish|s', 'fish|a', 'fish|v'),
      wd('tree|IDF', 'tree|s', 'tree|v'),
      wd('meat|IDF', 'meat|s'),
      wd('salad|IDF', 'salad|s'),
      wd('vegetable|IDF', 'vegetable|s', 'vegetable|a'),
      wd('green|IDF', 'green|s', 'green|a', 'green|v'),
      wd('red|IDF', 'red|s', 'red|a', 'red|v'),
      wd('red|IDF', 'red|s', 'red|a', 'red|v'),
      wd('blue|IDF', 'blue|s', 'blue|a', 'blue|v'),
      wd('blue|IDF', 'blue|s', 'blue|a', 'blue|v'),
      wd('yellow|IDF', 'yellow|s', 'yellow|a', 'yellow|v'),
      wd('white|IDF', 'white|s', 'white|a', 'white|v'),
      wd('leaves|IDF', 'leave|s', 'leaf|s', 'leave|v'),
      wd('yellow|IDF', 'yellow|s', 'yellow|a', 'yellow|v'),
      wd('colour|IDF', 'colour|s', 'colour|v'),
      wd('grey|IDF', 'grey|s'),
      wd('tobacco|IDF', 'tobacco|s'),
      wd('advertising|IDF', 'advertising|e'),
      wd('cigarette|IDF', 'cigarette|s'),
      wd('smoke|IDF', 'smoke|s', 'smoke|v'),
      wd('alcohol|IDF', 'alcohol|s'),
      wd('ban|IDF', 'ban|s'),
      wd('coal|IDF', 'coal|s'),
      wd('cigarette|IDF', 'cigarette|s'),
      wd('import|IDF', 'import|s', 'import|v'),
      wd('alcohol|IDF', 'alcohol|s'),
      wd('textile|IDF', 'textile|s'),
      wd('whiskey|IDF', 'whiskey|s'),
      wd('drink|IDF', 'drink|s', 'drink|v'),
      wd('whisky|IDF', 'whisky|s'),
      wd('hot water|SEQ', 'water, hot|q'),
      wd('warm dry|SEQ', 'dry, warm|q'),
      wd('yellow colour|SEQ', 'colour, yellow|q'),
      wd('white leaves|SEQ', 'leave, white|q'),
      wd('yellow white|SEQ', 'white, yellow|q'),
      wd('blue yellow|SEQ', 'yellow, blue|q'),
      wd('blue blue|SEQ', 'blue, blue|q'),
      wd('red blue|SEQ', 'blue, red|q'),
      wd('red red|SEQ', 'red, red|q'),
      wd('green red|SEQ', 'red, green|q'),
      wd('vegetable green|SEQ', 'green, vegetable|q'),
      wd('fish tree|SEQ', 'tree, fish|q'),
      wd('fresh fish|SEQ', 'fish, fresh|q'),
      wd('vegetable food|SEQ', 'food, vegetable|q'),
      wd('cool fruit|SEQ', 'fruit, cool|q'),
      wd('dry weather|SEQ', 'weather, dry|q'),
      wd('white cold|SEQ', 'cold, white|q'),
      wd('green white|SEQ', 'white, green|q'),
      wd('yellow green|SEQ', 'green, yellow|q'),
      wd('white yellow|SEQ', 'yellow, white|q'),
      wd('hot hot water|SEQ', 'water, hot hot|q'),
      wd('warm warm dry|SEQ', 'dry, warm warm|q'),
      wd('yellow white leaves|SEQ', 'leave, yellow white|q'),
      wd('blue yellow white|SEQ', 'white, blue yellow|q'),
      wd('blue blue yellow|SEQ', 'yellow, blue blue|q'),
      wd('red blue blue|SEQ', 'blue, red blue|q'),
      wd('red red blue|SEQ', 'blue, red red|q'),
      wd('green red red|SEQ', 'red, green red|q'),
      wd('vegetable green red|SEQ', 'red, vegetable green|q'),
      wd('fresh fish tree|SEQ', 'tree, fresh fish|q'),
      wd('warm dry weather|SEQ', 'weather, warm dry|q'),
      wd('green white cold|SEQ', 'cold, green white|q'),
      wd('yellow green white|SEQ', 'white, yellow green|q'),
      wd('white yellow green|SEQ', 'green, white yellow|q'),
      ai('EOF|'),
      ai('EOT|')
    ]
  end

  def test_basic
    meet({}, [
      # AS
      wd('Die|IDF', 'die|w'),
      wd('helle|IDF', 'hell|a'),
      wd('Sonne|IDF', 'sonne|s'),
      tk('.|PUNC'),
      # AK
      wd('Der|IDF', 'der|w'),
      wd('schöne|IDF', 'schön|a'),
      wd('Sonnenuntergang|COM', 'sonnenuntergang|k', 'sonne|s+', 'untergang|s+'),
      ai('EOF|'),
      ai('EOT|')
    ], [
      # AS
      wd('Die|IDF', 'die|w'),
      wd('helle|IDF', 'hell|a'),
      wd('Sonne|IDF', 'sonne|s'),
      tk('.|PUNC'),
      wd('helle Sonne|SEQ', 'sonne, hell|q'),
      # AK
      wd('Der|IDF', 'der|w'),
      wd('schöne|IDF', 'schön|a'),
      wd('Sonnenuntergang|COM', 'sonnenuntergang|k', 'sonne|s+', 'untergang|s+'),
      wd('schöne Sonnenuntergang|SEQ', 'sonnenuntergang, schön|q'),
      ai('EOF|'),
      ai('EOT|')
    ])
  end

  def test_param
    meet({ 'sequences' => [['SS', '1 2'], ['SSS', '1 2 3']] }, [
      # (AS)
      wd('Die|IDF', 'die|w'),
      wd('helle|IDF', 'hell|a'),
      wd('Sonne|IDF', 'sonne|s'),
      tk('.|PUNC'),
      # SS + SS + SSS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      # SS
      wd('Der|IDF', 'der|w'),
      wd('Sonne|IDF', 'sonne|s'),
      wd('Untergang|IDF', 'untergang|s'),
      ai('EOF|'),
      ai('EOT|')
    ], [
      # (AS)
      wd('Die|IDF', 'die|w'),
      wd('helle|IDF', 'hell|a'),
      wd('Sonne|IDF', 'sonne|s'),
      tk('.|PUNC'),
      # SS + SS + SSS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      wd('Abbild Gottes|SEQ', 'abbild gott|q'),
      wd('Gottes Turm|SEQ', 'gott turm|q'),
      wd('Abbild Gottes Turm|SEQ', 'abbild gott turm|q'),
      # SS
      wd('Der|IDF', 'der|w'),
      wd('Sonne|IDF', 'sonne|s'),
      wd('Untergang|IDF', 'untergang|s'),
      wd('Sonne Untergang|SEQ', 'sonne untergang|q'),
      ai('EOF|'),
      ai('EOT|')
    ])
  end

  def test_multi
    meet({ 'sequences' => [['MS', '1 2']] }, [
      # MS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      ai('EOF|'),
      ai('EOT|')
    ], [
      # MS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      wd('Abbild Gottes Turm|SEQ', 'abbild gottes turm|q'),
      ai('EOF|'),
      ai('EOT|')
    ])
    meet({ 'sequences' => [['MS', '1 2'], ['SS', '1 2'], ['SSS', '1 2 3']] }, [
      # MS + SS + SS + SSS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      # SS
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      ai('EOF|'),
      ai('EOT|')
    ], [
      # MS + SS + SS + SSS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      wd('Abbild Gottes Turm|SEQ', 'abbild gottes turm|q'),
      wd('Abbild Gottes|SEQ', 'abbild gott|q'),
      wd('Gottes Turm|SEQ', 'gott turm|q'),
      wd('Abbild Gottes Turm|SEQ', 'abbild gott turm|q'),
      # SS
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Abbild Gottes|SEQ', 'abbild gott|q'),
      ai('EOF|'),
      ai('EOT|')
    ])
  end

  def test_regex
    meet({ 'sequences' => [['[MS]S', '1 2']] }, [
      # MS + SS + SS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      # SS
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      ai('EOF|'),
      ai('EOT|')
    ], [
      # MS + SS + SS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      wd('Abbild Gottes Turm|SEQ', 'abbild gottes turm|q'),
      wd('Abbild Gottes|SEQ', 'abbild gott|q'),
      wd('Gottes Turm|SEQ', 'gott turm|q'),
      # SS
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Abbild Gottes|SEQ', 'abbild gott|q'),
      ai('EOF|'),
      ai('EOT|')
    ])
  end

  def test_regex_none
    meet({ 'sequences' => ['..'] }, [
      # (MS + SS + SS)
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      ai('EOF|'),
      ai('EOT|')
    ], [
      # (MS + SS + SS)
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      ai('EOF|'),
      ai('EOT|')
    ])
  end

  def test_regex_comm
    meet({ 'sequences' => ['(?#MS)..'] }, [  # = [MS][MS]
      # MS + SS + SS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      # SS
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      ai('EOF|'),
      ai('EOT|')
    ], [
      # MS + SS + SS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      wd('Abbild Gottes Turm|SEQ', 'abbild gottes turm|q'),
      wd('Abbild Gottes|SEQ', 'abbild gott|q'),
      wd('Gottes Turm|SEQ', 'gott turm|q'),
      # SS
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Abbild Gottes|SEQ', 'abbild gott|q'),
      ai('EOF|'),
      ai('EOT|')
    ])
  end

  def test_regex_quan
    meet({ 'sequences' => ['[MS]S+'] }, [
      # MS + SSS + (SS) + SS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      ai('EOF|'),
      ai('EOT|')
    ], [
      # MS + SSS + (SS) + SS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      wd('Abbild Gottes Turm|SEQ', 'abbild gottes turm|q'),
      wd('Abbild Gottes Turm|SEQ', 'abbild gott turm|q'),
      #wd('Abbild Gottes|SEQ', 'abbild gott|q'),  # FIXME
      wd('Gottes Turm|SEQ', 'gott turm|q'),
      ai('EOF|'),
      ai('EOT|')
    ])
  end

  def test_regex_form
    meet({ 'sequences' => [['[MS]S+', '^']] }, [
      # MS + SSS + (SS) + SS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      ai('EOF|'),
      ai('EOT|')
    ], [
      # MS + SSS + (SS) + SS
      wd('Der|IDF', 'der|w'),
      wd('Abbild Gottes|MUL', 'abbild gottes|m'),
      wd('Abbild|IDF', 'abbild|s'),
      wd('Gottes|IDF', 'gott|s'),
      wd('Turm|IDF', 'turm|s'),
      tk('.|PUNC'),
      wd('Abbild Gottes Turm|SEQ', 'ms:abbild gottes^turm|q'),
      wd('Abbild Gottes Turm|SEQ', 'sss:abbild^gott^turm|q'),
      #wd('Abbild Gottes|SEQ', 'ss:abbild^gott|q'),  # FIXME
      wd('Gottes Turm|SEQ', 'ss:gott^turm|q'),
      ai('EOF|'),
      ai('EOT|')
    ])
  end

  def test_match
    meet({ 'sequences' => [['WA', '1 2 (0)'], ['A[SK]', '0: 2, 1']] }, [
      # WA + AS
      wd('Die|IDF', 'die|w'),
      wd('helle|IDF', 'hell|a'),
      wd('Sonne|IDF', 'sonne|s'),
      tk('.|PUNC'),
      # WA + AK
      wd('Der|IDF', 'der|w'),
      wd('schöne|IDF', 'schön|a'),
      wd('Sonnenuntergang|COM', 'sonnenuntergang|k', 'sonne|s+', 'untergang|s+'),
      ai('EOF|'),
      ai('EOT|')
    ], [
      # WA + AS
      wd('Die|IDF', 'die|w'),
      wd('helle|IDF', 'hell|a'),
      wd('Sonne|IDF', 'sonne|s'),
      tk('.|PUNC'),
      wd('Die helle|SEQ', 'die hell (wa)|q'),
      wd('helle Sonne|SEQ', 'as: sonne, hell|q'),
      # WA + AK
      wd('Der|IDF', 'der|w'),
      wd('schöne|IDF', 'schön|a'),
      wd('Sonnenuntergang|COM', 'sonnenuntergang|k', 'sonne|s+', 'untergang|s+'),
      wd('Der schöne|SEQ', 'der schön (wa)|q'),
      wd('schöne Sonnenuntergang|SEQ', 'ak: sonnenuntergang, schön|q'),
      ai('EOF|'),
      ai('EOT|')
    ])
  end

  def test_nums
    meet({ 'sequences' => [['0SS', '1 2 3'], ['S0', '1 2']] }, [
      tk('3|NUMS'),
      wd('body|IDF', 'body|s'),
      wd('problem|IDF', 'problem|s'),
      tk('.|PUNC'),
      wd('area|IDF', 'area|s'),
      tk('51|NUMS'),
      ai('EOF|'),
      ai('EOT|')
    ], [
      tk('3|NUMS'),
      wd('body|IDF', 'body|s'),
      wd('problem|IDF', 'problem|s'),
      tk('.|PUNC'),
      wd('3 body problem|SEQ', '3 body problem|q'),
      wd('area|IDF', 'area|s'),
      tk('51|NUMS'),
      wd('area 51|SEQ', 'area 51|q'),
      ai('EOF|'),
      ai('EOT|')
    ])
  end

  def test_many_permutations
    meet({}, @perm, @out1)
  end

  def test_many_permutations_simple_regex1
    meet({ 'sequences' => [['A[SK]', '2, 1'], ['AA[SK]', '3, 1 2']] }, @perm, @out1)
  end

  def test_many_permutations_simple_regex2
    meet({ 'sequences' => [['A(S|K)', '2, 1'], ['AA(?:S|K)', '3, 1 2']] }, @perm, @out1)
  end

  def test_many_permutations_complex_regex
    meet({ 'sequences' => [['A{1}(S|K)', '2, 1'], ['A{2}(S|K)', '3, 1 2']] }, @perm, @out2)
  end unless ENV['LINGO_DISABLE_SLOW_TESTS'] # ~60s

end
