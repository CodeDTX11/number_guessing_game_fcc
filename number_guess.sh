#! /bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

RAND_NUM=$(( RANDOM % 1000 + 1));

#echo $RAND_NUM

echo "Enter your username:"

read USER
# check database for user
USER_INFO=$($PSQL "select user_id, username, games_played, best_game from users where username='$USER'")
#if old user, output info
if [[ -n $USER_INFO ]]
then
  IFS='|' read USER_ID USERNAME USER_NUM_GAMES USER_BEST_GAME <<< $USER_INFO
  echo "Welcome back, $USERNAME! You have played $USER_NUM_GAMES games, and your best game took $USER_BEST_GAME guesses."
  #     Welcome back, <username>! You have played <games_played> games, and your best game took <best_game> guesses.
else
  USER_ID=0
  USERNAME=$USER
  echo "Welcome, $USERNAME! It looks like this is your first time here."
fi
# else output new user info

NUM_GUESS=1

GUESS_NUM(){

  if [[ $1 ]]
  then
    echo -e "$1"
  fi
  
  read GUESS

  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    GUESS_NUM "That is not an integer, guess again:"
  elif [[ $GUESS == $RAND_NUM ]]
  then
    echo "You guessed it in $NUM_GUESS tries. The secret number was $RAND_NUM. Nice job!"
  elif [[ $GUESS > $RAND_NUM ]]
  then
    (( NUM_GUESS++ ))
    GUESS_NUM "It's lower than that, guess again:"
  else
    (( NUM_GUESS++ ))
    GUESS_NUM "It's higher than that, guess again:"
  fi

}

GUESS_NUM "Guess the secret number between 1 and 1000:" # function call

#after game is finished input into database the nubmer of games playes and number of guesses if less than previous attempt
if [[ $USER_ID == 0 ]] # new user so insert new user info into database
then
  NEW_USER=$($PSQL "insert into users (username, games_played, best_game) values('$USERNAME', 1, $NUM_GUESS)")
else # returning user, update num games and update best game if needed
  (( USER_NUM_GAMES++ ))
  if (( NUM_GUESS < USER_BEST_GAME )) # check if current games number of guesses lower than all time user best game guesses
  then
    UPDATE_USER=$($PSQL "UPDATE users set games_played=$USER_NUM_GAMES, best_game=$NUM_GUESS where user_id=$USER_ID") 
  else # if not best game then just update number of games
    UPDATE_USER=$($PSQL "UPDATE users set games_played=$USER_NUM_GAMES where user_id=$USER_ID") 
  fi
fi