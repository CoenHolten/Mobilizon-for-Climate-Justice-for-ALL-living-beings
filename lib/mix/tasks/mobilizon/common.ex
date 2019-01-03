# Portions of this file are derived from Pleroma:
# Copyright © 2017-2018 Pleroma Authors <https://pleroma.social>
# SPDX-License-Identifier: AGPL-3.0-only
# Upstream: https://git.pleroma.social/pleroma/pleroma/blob/develop/lib/mix/tasks/pleroma/common.ex

defmodule Mix.Tasks.Mobilizon.Common do
  @moduledoc "Common functions to be reused in mix tasks"

  def get_option(options, opt, prompt, defval \\ nil, defname \\ nil) do
    display = if defname || defval, do: "#{prompt} [#{defname || defval}]", else: "#{prompt}"

    Keyword.get(options, opt) ||
      case Mix.shell().prompt(display) do
        "\n" ->
          case defval do
            nil -> get_option(options, opt, prompt, defval)
            defval -> defval
          end

        opt ->
          opt |> String.trim()
      end
  end

  def escape_sh_path(path) do
    ~S(') <> String.replace(path, ~S('), ~S(\')) <> ~S(')
  end
end
