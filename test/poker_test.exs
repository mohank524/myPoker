defmodule PokerTest do
  use ExUnit.Case

  doctest Poker

  defstruct header: "", data: ""

  test "Test cases for poker " do
      [header | data] = Path.absname("input.csv")
      |> File.stream!
      |> Enum.to_list
      |> Enum.map(&String.trim/1)

      %PokerTest{ header: header, data: data }
      for input <- data do
        [black, white, result] = String.split(input,",,")
        assert Poker.main(Black: String.split(black,",") , White: String.split(white,",")) == result
      end
  end
end
