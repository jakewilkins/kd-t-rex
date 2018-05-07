defmodule KdTree.Tree do
  use GenServer

  import Enum, only: [at: 2]

  defmodule Node do
    defstruct coords: [], left: [], right: []
  end

  @name __MODULE__

  @starting_state %{tree: nil, dimensions: nil}

  def starting_state do
    @starting_state
  end

  def start_link do
    GenServer.start_link(@name, [])
  end

  def init([]) do
    {:ok, starting_state()}
  end

  def handle_call({:setup, tree}, _from, state) do
    state = build_tree(tree, state)

    {:reply, :ok, state}
  end

  def handle_call({:nearest, point}, _from, state) do
    nearest = find_nearest(state, point)

    {:reply, nearest, state}
  end

  defp build_tree(points, state, depth \\ 0)
  defp build_tree([], _state, _depth), do: nil

  defp build_tree(points, %{dimensions: nil} = state, depth) do
    dimensions = points |> Enum.at(0) |> Enum.count()
    build_tree(points, %{state | dimensions: dimensions}, depth)
  end

  defp build_tree(points, %{dimensions: dimensions} = state, depth) do
    # IO.inspect state
    # IO.inspect depth
    # IO.inspect dimensions
    axis = rem(depth, dimensions)
    median = ((points |> Enum.count()) / 2) |> round

    # IO.puts "dimensions #{dimensions} | axis #{axis} | median #{median}"

    points = points |> Enum.sort(&(&1 |> Enum.at(axis) >= &2 |> Enum.at(axis)))
    {left, right} = points |> Enum.split(median)
    {median, left} = left |> List.pop_at((left |> Enum.count()) - 1)
    depth = depth + 1

    # IO.inspect median
    # IO.inspect depth
    # IO.inspect left
    # IO.inspect right
    %{
      state
      | tree: %Node{
          coords: median,
          left: build_tree(left, state, depth) |> get_tree,
          right: build_tree(right, state, depth) |> get_tree
        }
    }
  end

  defp find_nearest(state, point, k \\ 3, depth \\ 0, found \\ [])

  defp find_nearest(%{tree: %{left: nil, right: nil}} = state, point, k, _depth, found) do
    check_node(state.tree.coords, point, found, k)
  end

  defp find_nearest(%{tree: %{right: nil}} = state, point, k, depth, found) do
    # found = check_node(state.tree.coords, point, found, k)
    find_nearest(%{state | tree: state.tree.left}, point, k, depth + 1, found)
  end

  defp find_nearest(%{tree: %{left: nil}} = state, point, k, depth, found) do
    # found = check_node(state.tree.coords, point, found, k)
    find_nearest(%{state | tree: state.tree.right}, point, k, depth + 1, found)
  end

  defp find_nearest(%{tree: tree, dimensions: dimensions} = state, point, k, depth, found) do
    # IO.puts "checking #{state |> inspect}"
    found = check_node(state.tree.coords, point, found, k)

    axis = calculate_axis(depth, dimensions)

    left_distance = calculate_distance(tree.left.coords, point)
    right_distance = calculate_distance(tree.right.coords, point)

    closest = if left_distance > right_distance, do: :right, else: :left
    farthest = if left_distance > right_distance, do: :left, else: :right

    found = find_nearest(%{state | tree: Map.get(tree, closest)}, point, k, depth + 1, found)

    # found = if at(point, axis) <= at(tree.left.coords, axis) do
    #   find_nearest(%{state | tree: tree.left}, point, k, depth + 1, found)
    # else
    #   found
    # end

    some_number = :math.pow(at(point, axis) - at(Map.get(tree, farthest).coords, axis), 2)
    {furthest_distance, _} = List.last(found)

    found =
      if some_number < furthest_distance do
        find_nearest(%{state | tree: Map.get(tree, farthest)}, point, k, depth + 1, found)
      else
        found
      end

    found
  end

  defp check_node(tree_node, point, [], _k) do
    # IO.puts "initializing found with #{point |> inspect}"
    [{calculate_distance(tree_node, point), tree_node}]
  end

  defp check_node(tree_node, point, found, k) do
    # IO.puts "checking node #{inspect tree_node}"
    # IO.puts "found: #{inspect found}"
    distance = calculate_distance(tree_node, point)
    {furthest_found_distance, _} = List.last(found)

    cond do
      found |> length < k ->
        [{distance, tree_node} | found]
        |> sorted_by_distance

      distance < furthest_found_distance ->
        [{distance, tree_node} | found]
        |> sorted_by_distance
        |> List.delete_at(k)

      true ->
        found
    end
  end

  defp calculate_axis(depth, dimensions), do: rem(depth, dimensions)

  defp calculate_distance(nil, _), do: nil

  defp calculate_distance([x_one, y_one], [x_two, y_two]) do
    c = x_one - x_two
    d = y_one - y_two
    c * c + d * d
  end

  defp sorted_by_distance(list) do
    list |> Enum.sort(fn {distance_a, _}, {distance_b, _} -> distance_a <= distance_b end)
  end

  defp get_tree(nil), do: nil
  defp get_tree(state), do: state.tree
end
