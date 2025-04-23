rankedpickorder = {
  phase = 'start',
  banChoices = {},
  bans = {},

  ["order"] = {
    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_GOODGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_BADGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_BADGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_GOODGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_GOODGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_BADGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_BADGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_GOODGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_GOODGUYS,
      ["hero"] = "empty",
      --canRandom = false
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_BADGUYS,
      ["hero"] = "empty",
      --canRandom = false
    }
  },
}

if GetMapName() == "10v10" or GetMapName() == "oaa_bigmode" or GetMapName() == "oaa_alternate" then
  rankedpickorder.order = {
    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_GOODGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_BADGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_GOODGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_BADGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_GOODGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_BADGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_GOODGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_BADGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_GOODGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_BADGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_GOODGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_BADGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_GOODGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_BADGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_GOODGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_BADGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_GOODGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_BADGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_GOODGUYS,
      ["hero"] = "empty"
    },

    {
      ["type"] = "Pick",
      ["team"] = DOTA_TEAM_BADGUYS,
      ["hero"] = "empty"
    }
  }
end
