#!/bin/bash

# Connect to PostgreSQL
PSQL="psql -X --username=freecodecamp --dbname=number_guess --tuples-only -c"

# Generate a random number
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Prompt for username
echo "Enter your username:"
read USERNAME

# Trim whitespace from username
USERNAME=$(echo "$USERNAME" | sed -r 's/^ *| *$//g')

# Check if user exists in the database
USER_DATA=$($PSQL "SELECT games_played, COALESCE(best_game, 0) FROM users WHERE username='$USERNAME'")

if [[ -z $USER_DATA ]]
then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  INSERT_USER=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, NULL)")
  GAMES_PLAYED=0
  BEST_GAME=0
else
  # Properly extract data
  IFS="|" read -r GAMES_PLAYED BEST_GAME <<< "$USER_DATA"

  # Correctly formatted welcome message
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Start game
echo "Guess the secret number between 1 and 1000:"
NUMBER_OF_GUESSES=0

while true
do
  read GUESS
  ((NUMBER_OF_GUESSES++))

  # Validate input
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
  elif [[ $GUESS -lt $SECRET_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
  else
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    
    # Update games played
    ((GAMES_PLAYED++))
    
    # Update best game if it's the first game or if this game is better
    if [[ $BEST_GAME -eq 0 || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]
    then
      BEST_GAME=$NUMBER_OF_GUESSES
    fi
    
    UPDATE_USER=$($PSQL "UPDATE users SET games_played=$GAMES_PLAYED, best_game=$BEST_GAME WHERE username='$USERNAME'")

    break
  fi
done
