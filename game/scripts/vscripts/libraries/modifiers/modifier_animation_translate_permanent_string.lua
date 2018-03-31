
modifier_animation_translate_permanent_string = class(ModifierBaseClass)

function modifier_animation_translate_permanent_string:OnCreated(keys)
  self.translate = keys.translate
end

function modifier_animation_translate_permanent_string:GetAttributes()
  return MODIFIER_ATTRIBUTE_PERMANENT + MODIFIER_ATTRIBUTE_IGNORE_INVULNERABLE + MODIFIER_ATTRIBUTE_MULTIPLE
end

function modifier_animation_translate_permanent_string:IsHidden()
  return true
end

function modifier_animation_translate_permanent_string:IsDebuff()
  return false
end

function modifier_animation_translate_permanent_string:IsPurgable()
  return false
end

function modifier_animation_translate_permanent_string:DeclareFunctions()
  local funcs = {
    MODIFIER_PROPERTY_TRANSLATE_ACTIVITY_MODIFIERS,
  }

  return funcs
end

function modifier_animation_translate_permanent_string:GetActivityTranslationModifiers(...)
  return self.translate or 'run'
end
