defmodule SwarmWeb.Api.DatasetControllerTest do
  use SwarmWeb.ApiCase
  use SwarmEngine.DataCase

  alias SwarmEngine.Dataset

  @create_attrs %{
    "name" => "My Dataset",
    "source" => %{
      "type" => "LocalFile",
      "path" => "tmp.txt"
    },
    "decoder" => %{
      "type" => "CSV",
      "headers" => true,
      "separator" => ",",
      "delimiter" => "/n"
    }
  }

  @update_attrs %{name: "some updated name"}
  @invalid_attrs %{name: nil}

  def fixture(:dataset) do
    {:ok, dataset} = SwarmEngine.create_dataset(@create_attrs)
    dataset
  end

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "GET /index" do
    test "lists all datasets", context do
      %{conn: conn} = sign_in(context)

      conn = get conn, dataset_path(conn, :index)
      assert json_response(conn, 200)["data"] == []
    end

    test "unauthenticated access", %{conn: conn} do
      conn = get conn, dataset_path(conn, :index)
      assert json_response(conn, 401)["message"] == "unauthenticated"
    end
  end

  describe "create dataset" do
    setup [:sign_in]

    test "renders dataset when data is valid", %{conn: conn} do
      res = post conn, dataset_path(conn, :create), dataset: @create_attrs
      assert %{"id" => id} = json_response(res, 201)["data"]

      res = get conn, dataset_path(conn, :show, id)

      assert json_response(res, 200)["data"] == %{
        "id" => id,
        "name" => "My Dataset",
        "decoder" => %{
          "type" => "CSV",
          "delimiter" => "/n",
          "headers" => true,
          "separator" => ","
        },
        "tracker" => %{
          "resources" => [],
          "source" => %{"type" => "LocalFile", "path" => "tmp.txt"}
        },
        "store" => %{"columns" => [], "name" => nil}
      }
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, dataset_path(conn, :create), dataset: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update dataset" do
    setup [:sign_in, :create_dataset]

    test "renders dataset when data is valid", %{conn: conn, dataset: %Dataset{id: id} = dataset} do
      res = put conn, dataset_path(conn, :update, dataset), dataset: @update_attrs
      assert %{} = json_response(res, 200)["data"]

      res = get conn, dataset_path(conn, :show, id)
      assert json_response(res, 200)["data"] == %{
        "id" => id,
        "name" => "some updated name",
        "decoder" => %{
          "type" => "CSV",
          "delimiter" => "/n",
          "headers" => true,
          "separator" => ","
        },
        "tracker" => %{
          "resources" => [],
          "source" => %{"type" => "LocalFile", "path" => "tmp.txt"}
        },
        "store" => %{"columns" => [], "name" => nil}
      }
    end

    test "renders errors when data is invalid", %{conn: conn, dataset: dataset} do
      conn = put conn, dataset_path(conn, :update, dataset), dataset: @invalid_attrs
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete dataset" do
    setup [:sign_in, :create_dataset]

    test "deletes chosen dataset", %{conn: conn, dataset: dataset} do
      res = delete conn, dataset_path(conn, :delete, dataset)
      assert response(res, 204)
      assert_error_sent 404, fn ->
        get conn, dataset_path(conn, :show, dataset)
      end
    end
  end

  defp create_dataset(_) do
    dataset = fixture(:dataset)
    {:ok, dataset: dataset}
  end
end