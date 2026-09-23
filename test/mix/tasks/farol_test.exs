defmodule Mix.Tasks.FarolTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  @tmp Path.join(System.tmp_dir!(), "farol_mix_task_test")

  setup do
    Mix.Task.reenable("farol")
    File.rm_rf!(@tmp)
    File.mkdir_p!(@tmp)
    :ok
  end

  defp write_template(name, content) do
    path = Path.join(@tmp, name)
    File.write!(path, content)
    path
  end

  test "passes silently when templates are accessible" do
    path = write_template("ok.heex", ~s(<button type="button">save</button>))

    output = capture_io(fn -> Mix.Tasks.Farol.run([path]) end)

    assert output =~ "0 accessibility finding(s)"
  end

  test "fails with a didactic report on error-severity findings" do
    path = write_template("bad.heex", "<div>\n  <img src=\"a.jpg\">\n</div>")

    output =
      capture_io(fn ->
        assert_raise Mix.Error, "farol: accessibility audit failed", fn ->
          Mix.Tasks.Farol.run([path])
        end
      end)

    assert output =~ "[img-alt]"
    assert output =~ "#{path}:2"
  end

  test "warnings alone do not fail the run" do
    path = write_template("warn.heex", ~s|<button phx-click={JS.toggle(to: "#x")}>open</button>|)

    capture_io(fn -> Mix.Tasks.Farol.run([path]) end)
  end

  test "--except skips rules" do
    path = write_template("except.heex", ~s(<img src="a.jpg">))

    capture_io(fn -> Mix.Tasks.Farol.run([path, "--except", "img-alt"]) end)
  end

  test "--format sarif --output writes a sarif document" do
    template = write_template("sarif.heex", ~s(<img src="a.jpg">))
    sarif_path = Path.join(@tmp, "farol.sarif")

    capture_io(fn ->
      assert_raise Mix.Error, fn ->
        Mix.Tasks.Farol.run([template, "--format", "sarif", "--output", sarif_path])
      end
    end)

    doc = sarif_path |> File.read!() |> JSON.decode!()
    assert doc["version"] == "2.1.0"

    [result] = doc["runs"] |> hd() |> Map.fetch!("results")
    assert result["ruleId"] == "img-alt"

    assert get_in(result, [
             "locations",
             Access.at(0),
             "physicalLocation",
             "artifactLocation",
             "uri"
           ]) ==
             template
  end

  test "unparseable templates fail with file and line" do
    path = write_template("broken.heex", ~s(<div><span></div>))

    assert capture_io(:stderr, fn ->
             capture_io(fn ->
               assert_raise Mix.Error, fn -> Mix.Tasks.Farol.run([path]) end
             end)
           end) =~ path
  end

  test "complains when no templates are found" do
    assert_raise Mix.Error, ~r/no .heex templates found/, fn ->
      capture_io(fn -> Mix.Tasks.Farol.run([Path.join(@tmp, "nada/*.heex")]) end)
    end
  end
end
