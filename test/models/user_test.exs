defmodule Pxblog.UserTest do
  use Pxblog.ModelCase
  import Comeonin.Bcrypt, only: [checkpw: 2]

  alias Pxblog.User
  alias Pxblog.TestHelper

  @valid_attrs %{email: "some content", password: "some content", password_confirmation: "some content", username: "some content"}
  @invalid_attrs %{}

  setup do
    {:ok, role} = TestHelper.create_role(%{name: "user", admin: false})
    {:ok, role: role}
  end

  defp valid_attrs(role) do
    Map.put(@valid_attrs, :role_id, role.id)
  end

  test "changeset with valid attributes", %{role: role} do
    changeset = User.changeset(%User{}, valid_attrs(role))
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = User.changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "password_digest value gets set to an hash" do
    changeset = User.changeset(%User{}, @valid_attrs)
    assert checkpw(@valid_attrs.password, Ecto.Changeset.get_change(changeset, :password_digest))
  end

  test "password_digest value does not get set if password is nil" do
    changeset = User.changeset(%User{}, %{email: "test@test.com", password: nil, password_confirmation: nil, username: "test"})
    refute Ecto.Changeset.get_change(changeset, :password_digest)
  end

  test "changeset is invalid if password and confirmation do not match" do
    changeset = User.changeset(%User{}, %{email: "test@test.com", password: "foo", password_confirmation: "bar", username: "test"})
    refute changeset.valid?
    assert changeset.errors[:password_confirmation] == "does not match password!"
  end

  test "changeset is invalid if username is used already", %{role: role} do
    %User{}
    |> User.changeset(valid_attrs(role))
    |> Pxblog.Repo.insert!
    user2 =
      %User{}
      |> User.changeset(valid_attrs(role))
    assert {:error, changeset} = Repo.insert(user2)
    assert changeset.errors[:username] == "has already been taken"
  end
  
  test "changeset is invalid if email is used already", %{role: role} do
    user2_attrs = valid_attrs(role) |> Map.put(:username, "test2")
    %User{}
    |> User.changeset(valid_attrs(role))
    |> Pxblog.Repo.insert!
    user2 =
      %User{}
      |> User.changeset(user2_attrs)
    assert {:error, changeset} = Repo.insert(user2)
    assert changeset.errors[:email] == "has already been taken"
  end

  test "changeset is invalid if password is too short" do
    attrs = @valid_attrs |> Map.put(:password, "t") |> Map.put(:password_confirmation, "t")
    changeset =
      %User{}
      |> User.changeset(attrs)
    refute changeset.valid?
    assert Dict.has_key?(changeset.errors, :password)
  end

end
