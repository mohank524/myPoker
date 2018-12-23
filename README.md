# Poker

$ git clone https://github.com/mohank524/myPoker.git

$ cd myPoker/

$ mix deps.get

$ iex -S mix

```
Poker.main(Black: ~w(2H 3D 5S 9C KD), White: ~w(2D 3H 5C 9S KH))
"Tie"
Poker.main(Black: ~w(2H 3D 5S 9C KD), White: ~w(2C 3H 4S 8C KH))
"Black wins -  high card: 9"
Poker.main(Black: ~w(2H 4S 4C 3D 4H), White: ~w(2S 8S AS QS 3S))
"White wins - flush 3"
Poker.main(Black: ~w(2H 3D 5S 9C KD), White: ~w(2C 3H 4S 8C AH))
"White wins - high card: Ace"
```
To run the test case.

$ mix test