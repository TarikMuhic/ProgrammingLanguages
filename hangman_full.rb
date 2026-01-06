require 'json'
require 'io/console'
require 'colorize'

# ------------------ HANGMAN STAGES -------------------
STAGES = [
  "\n  +---+\n  |   |\n      |\n      |\n      |\n      |\n=========\n",
  "\n  +---+\n  |   |\n  O   |\n      |\n      |\n      |\n=========\n",
  "\n  +---+\n  |   |\n  O   |\n  |   |\n      |\n      |\n=========\n",
  "\n  +---+\n  |   |\n  O   |\n /|   |\n      |\n      |\n=========\n",
  "\n  +---+\n  |   |\n  O   |\n /|\\  |\n      |\n      |\n=========\n",
  "\n  +---+\n  |   |\n  O   |\n /|\\  |\n /    |\n      |\n=========\n",
  "\n  +---+\n  |   |\n  O   |\n /|\\  |\n / \\  |\n      |\n=========\n"
]

SCORE_FILE = "C:/Users/tarik/Desktop/PL/src/scoreboard.json"
SAVE_FILE  = "C:/Users/tarik/Desktop/PL/src/save.json"

# ------------------ SCOREBOARD -------------------
def load_scoreboard
  if File.exist?(SCORE_FILE)
    
    JSON.parse(File.read(SCORE_FILE))
  else
    puts "Scoreboard file not found at #{SCORE_FILE}"  # debug line
    {}
  end
end


def save_scoreboard(scoreboard)
  File.write(SCORE_FILE, JSON.pretty_generate(scoreboard))
end

def update_scoreboard(player, won)
  scoreboard = load_scoreboard
  scoreboard[player] ||= { "wins" => 0, "games_played" => 0 }
  scoreboard[player]["games_played"] += 1
  scoreboard[player]["wins"] += 1 if won
  save_scoreboard(scoreboard)
end

def show_scoreboard
  scoreboard = load_scoreboard
  puts "\n==== SCOREBOARD ====".green.bold
  if scoreboard.empty?
    puts "No scores yet!"
  else
    scoreboard.sort_by { |_k, v| -v["wins"] }.each do |name, stats|
      puts "#{name.yellow}: #{stats['wins'].to_s.cyan} wins | #{stats['games_played']} games played"
    end
  end
  puts "=====================\n".green
  print "Press Enter to return to menu..."
  gets
end

# ------------------ SAVE / LOAD -------------------
def save_game(state)
  File.write(SAVE_FILE, JSON.pretty_generate(state))
  puts "\nGame saved successfully!".blue
end

def load_game
  if File.exist?(SAVE_FILE)
    JSON.parse(File.read(SAVE_FILE))
  else
    puts "No saved game found.".red
    nil
  end
end

# ------------------ INPUT HELPERS -------------------
def get_input(prompt)
  print prompt
  gets.chomp
end

def get_hidden_input(prompt)
  print prompt
  STDIN.noecho(&:gets).chomp.tap { puts }
end

# ------------------ GAMEPLAY -------------------
def play_game(state)
  loop do
    puts STAGES[6 - state['lives']]
    puts "\nWord: #{state['placeholder'].chars.join(' ')}"
    puts "Lives remaining: #{state['lives'].to_s.red}"
    puts "Guessed letters: #{state['guessed_letters'].join(', ')}"

    print "\nEnter a letter (or ':save'): "
    guess = gets.chomp.downcase

    if guess == ":save"
      save_game(state)
      puts "Returning to main menu...".blue
      return
    end

    if guess.length != 1 || guess !~ /[a-z]/
      puts "Please enter a valid letter!".yellow
      next
    end

    if state['guessed_letters'].include?(guess)
      puts "You already guessed that!".yellow
      next
    end

    state['guessed_letters'] << guess

    if state['word'].include?(guess)
      puts "Correct!".green
      state['placeholder'] = state['word'].chars.map { |ch| state['guessed_letters'].include?(ch) ? ch : "_" }.join

      if state['placeholder'] == state['word']
        puts STAGES[6]
        puts "\n🎉 YOU WIN! 🎉".green.bold
        puts "The word was '#{state['word']}'".green
        update_scoreboard(state['player'], true)
        break
      end
    else
      state['lives'] -= 1
      puts "Wrong!".red

      if state['lives'] <= 0
        puts STAGES[6]
        puts "\n💀 YOU LOST! 💀".red.bold
        puts "The word was '#{state['word']}'".red
        update_scoreboard(state['player'], false)
        break
      end
    end
  end

  # After game ends, automatically return to main menu
  puts "\nReturning to main menu...".blue
end

# ------------------ MAIN MENU -------------------
def main_menu
  loop do
    puts "\n╔════════════════════════╗"
    puts "║      HANGMAN GAME      ║".cyan.bold
    puts "╚════════════════════════╝"
    puts "1. New Game"
    puts "2. Continue Saved Game"
    puts "3. View Scoreboard"
    puts "4. Exit"

    print "\nChoose option: "
    case gets.chomp
    when "1"
      new_game
    when "2"
      state = load_game
      play_game(state) if state
    when "3"
      show_scoreboard
    when "4"
      puts "Goodbye!".blue
      exit
    else
      puts "Invalid option!".red
    end
  end
end

# ------------------ NEW GAME -------------------
def new_game
  mode = get_input("Multiplayer? (yes/no): ").downcase
  player1 = get_input("Enter Player 1 name: ")

  if mode == "yes"
    player2 = get_input("Enter Player 2 name: ")
    chooser = get_input("Should Player 1 choose the word? (yes/no): ")

    word =
      if chooser == "yes"
        get_hidden_input("Player 1, enter the word: ")
      else
        %w[bicycle hangman elephant laptop programming ruby coding fantasy miracle planet crystal].sample
      end

    player = player2
  else
    word = %w[bicycle hangman elephant laptop programming ruby coding fantasy miracle planet crystal].sample
    player = player1
  end

  state = {
    "player" => player,
    "word" => word.downcase,
    "placeholder" => "_" * word.length,
    "guessed_letters" => [],
    "lives" => 6
  }

  puts "\nGame started! Good luck, #{player.yellow}!"
  play_game(state)
end

# ------------------ START -------------------
main_menu
