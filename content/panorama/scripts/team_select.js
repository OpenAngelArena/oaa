
FindDotaHudElement('PreGame').style.opacity = 0;
FindDotaHudElement('PreGame').style.visibility = 'collapse';

function FindDotaHudElement(id) {
  return GetDotaHud().FindChildTraverse(id)
}

function GetDotaHud() {
  var p = $.GetContextPanel()
  try {
    while (true) {
      if (p.id === "Hud")
        return p
      else
        p = p.GetParent()
    }
  } catch (e) {}
}
