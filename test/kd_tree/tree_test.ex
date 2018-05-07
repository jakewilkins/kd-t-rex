defmodule KdTreeTreeTest do
  use ExUnit.Case
  doctest KdTree.Tree

  alias KdTree.Tree

  import Tree, only: [starting_state: 0]

  @points [
    [2, 3],
    [5, 4],
    [9, 6],
    [4, 7],
    [8, 1],
    [7, 2]
  ]

  test "tree" do
    # IO.puts "asdfasdfasdf '#{inspect starting_state()}'"
    {:reply, :ok, %{tree: tree}} = Tree.handle_call({:setup, @points}, nil, starting_state())

    # IO.inspect(tree)

    assert tree.coords == [7, 2]

    assert tree.left.coords == [9, 6]
    assert tree.left.right.coords == [8, 1]

    assert tree.right.coords == [5, 4]
    assert tree.right.left.coords == [4, 7]
    assert tree.right.right.coords == [2, 3]
  end

  test "nearest" do
    {:reply, :ok, state} = Tree.handle_call({:setup, @points}, nil, starting_state())

    {:reply, nearest, _state} = Tree.handle_call({:nearest, [4, 7]}, nil, state)
    IO.inspect(nearest)
    {:reply, nearest, _state} = Tree.handle_call({:nearest, [8, 1]}, nil, state)
    IO.inspect(nearest)
    {:reply, nearest, _state} = Tree.handle_call({:nearest, [2, 3]}, nil, state)
    IO.inspect(nearest)
    {:reply, nearest, _state} = Tree.handle_call({:nearest, [5, 4]}, nil, state)
    IO.inspect(nearest)
    {:reply, nearest, _state} = Tree.handle_call({:nearest, [4, 4]}, nil, state)
    IO.inspect(nearest)
  end
end
