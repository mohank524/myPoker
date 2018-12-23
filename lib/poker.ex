defmodule Poker do

  @suits ~w(H D S C)
  @order ~w(straight_flush four_of_a_kind full_house flush straight three_of_a_kind two_pairs pair high_card)a

  def hello() do
    :world
  end

  def main(Black: black_input, White: white_input) do
    {:ok, black_cards } = validate_card(black_input)
    {:ok, white_cards } = validate_card(white_input)
    get_card(black_cards, white_cards)
        |> result
        |> Tuple.to_list
        |> Enum.join(" ")
  end

  def get_card(b, w), do: get_card(b, w, 0)
  def get_card(black_cards, white_cards, offset) do
    {black_index, black_rank, black_value} = highest_card(black_cards, offset)
    {white_index, white_rank, white_value} = highest_card(white_cards, offset)

    cond do
      black_index < white_index-> {"Black wins -", black_rank, black_value}
      black_index > white_index-> {"White wins -", white_rank, white_value}
      black_value> white_value -> {"Black wins -", black_rank, black_value}
      black_value< white_value -> {"White wins -", white_rank, white_value}
      black_rank == "high card:" -> card_high_cards(black_cards, white_cards)
      true -> get_card(black_cards, white_cards, offset + 1)
    end
  end

  def card_high_cards(black_cards, white_cards) do
    b_values = black_cards
        |> Enum.map(&(&1[:value]))
        |> Enum.reverse
    white_values = white_cards
        |> Enum.map(&(&1[:value]))
        |> Enum.reverse

    new_pair = Enum.zip(b_values, white_values)
        |> Enum.reject(fn {b, w} -> b == w end)
        |> List.first

    case new_pair do
      {b, w} when b > w -> {"Black wins -"," high card:", b}
      {b, w} when b < w -> {"White wins -"," high card:", w}
      _ -> {"Tie"}
    end
  end

  def result({tie}), do: {tie}
  def result({winer, rank, value}), do: {winer,rank, number_to_symbol(value)}

def validate_card([]), do:
    {:error, :invalid_hand_size}
    def validate_card(larger_hand) when length(larger_hand) > 5, do: {:error, :invalid_hand_size}
     def validate_card(list) do

    with true <- length(Enum.uniq(list)) == length(list),
      proceed_cards <- Enum.map(list, &parse_card/1),
      {:invalid_cards, []} <- {:invalid_cards, Keyword.get_values(proceed_cards, :error)},
      cards <- Keyword.get_values(proceed_cards, :ok)
    do
      {:ok, cards}
    else
      false -> {:error, :repeated_card}
      {:invalid_cards, [_]} -> {:error, :invalid_card_in_hand}
    end
  end

  def parse_card(bin) do
    with literal_suit <- String.last(bin),
        {:ok, suit} <- parse_suit(literal_suit),
        literal_value <- String.trim_trailing(bin, literal_suit),
        value <- symbol_to_number(literal_value)
    do
      {:ok, [suit: suit, value: value]}
    else
      _ -> {:error, :invalid_card}
    end
  end

  def symbol_to_number("A"), do: 14
  def symbol_to_number("10"), do: 10
  def symbol_to_number("J"), do: 11
  def symbol_to_number("Q"), do: 12
  def symbol_to_number("K"), do: 13
  def symbol_to_number(bin) do
    case Integer.parse(bin) do
      {num, ""} when num in 2..14 -> num
      _ -> {:error, :invalid_card_value}
    end
  end

  def number_to_symbol(invalid_value) when invalid_value not in 1..14, do: {:error, :invalid_card_value}
  def number_to_symbol(ace) when ace == 14, do: "Ace"
  def number_to_symbol(11), do: "Jack"
  def number_to_symbol(10), do: "Ten"
  def number_to_symbol(12), do: "Queen"
  def number_to_symbol(13), do: "King"
  def number_to_symbol(num), do: num

  def parse_suit(bin) when bin in @suits, do: {:ok, String.upcase(bin)}
  def parse_suit(_wrong_suite), do: {:error, :invalid_suit}

  def highest_card([]), do: {}
  def highest_card(cards), do: highest_card(cards, 0)
  def highest_card(_cards, invalid_offset) when invalid_offset < 0 or invalid_offset >= length(@order) do
    {:error, :invalid_offset}
  end
  def highest_card(cards, offset) do
    ranks = @order
        |> Enum.slice(offset, length(@order))
    Enum.find_value(ranks, {}, fn rank_name ->
      rank_func = "get_#{rank_name}" |> String.to_atom
      case apply(Poker, rank_func, [cards]) do
        {rank_name, value} -> {Enum.find_index(@order, &(&1 == rank_name)), rank_name, value}
        _ -> false
      end
    end)
  end

  def get_straight(cards) do
    cards = cards
        |> Enum.map(&(&1[:value]))
        |> ace_as_one

    with lower <- cards |> List.first,
      upper <- cards |> List.last,
      sequence <- lower..upper |> Enum.to_list,
      true <- cards == sequence
    do
      {:straight, upper}
    else
      _ -> {}
    end
  end

  def ace_as_one([2,3,4,5,14]), do: [1,2,3,4,5]
  def ace_as_one([14,2,3,4,5]), do: [1,2,3,4,5]
  def ace_as_one(values), do: values

  def get_flush(cards) do
    cards
        |> group_by(:suit)
        |> Map.values
        |> Enum.member?(5)
        |> case do
            true -> {:flush, List.last(cards)[:value]}
            _ -> {}
        end
  end

  def get_straight_flush(cards) do
    with {:straight, value} <- get_straight(cards),
      {:flush, ^value} <- get_flush(cards)
    do
      {:straight_flush, value}
    else
      _ -> {}
    end
  end

  def get_pair(cards) do
    pairs = cards
        |> group_by(:value)
        |> Enum.filter(fn {_value, hits} -> hits > 1 end)

    case pairs do
      [] -> {}
      _ -> {"pair", pairs |> List.last |> Tuple.to_list |> List.first }
    end
  end

  def get_two_pairs(cards) do
    pairs = cards
      |> group_by(:value)
      |> Enum.filter(fn {_value, hits} -> hits > 1 end)

    cond do
      length(pairs) > 1 ->
        {"two pairs", pairs |> List.last |> Tuple.to_list |> List.first }
      true ->
        {}
    end
  end


  def get_four_of_a_kind(cards) do
    {value, 4} = cards
        |> group_by(:value)
        |> Enum.find({0, 4}, fn {_value, hits} -> hits == 4 end)

    case value do
      0 -> {}
      _ -> {"four of a kind", value }
    end
  end


  def get_three_of_a_kind(cards) do
    {value, _hits} = cards
        |> group_by(:value)
        |> Enum.find({0, 3}, fn {_value, hits} -> hits >= 3 end)

    case value do
      0 -> {}
      _ -> {"three of a kind", value }
    end
  end

  def get_full_house(cards) do
    with groups <- cards
        |> group_by(:value),
        hits <- Map.values(groups),
        [2, 3] <- Enum.sort(hits)
    do
        highest_card_value = groups |> Map.keys |> List.last
        {"full house", highest_card_value}
    else
      _ -> {}
    end
  end

  def get_high_card(cards) do
    value = cards
        |> List.last
        |> Keyword.get(:value)
        {"high card:", value}
  end

  def group_by(cards, field) do
    cards
    |> Enum.reduce(%{}, fn card, acc ->
        val = card[field]
        hits = case acc[val] do
          nil -> 1
          _ -> acc[val] + 1
        end
        Map.put(acc, val, hits)
      end)
  end
end
