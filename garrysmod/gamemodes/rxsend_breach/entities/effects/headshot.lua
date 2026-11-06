AddCSLuaFile()
function EFFECT:Init(data)
 local ent=data:GetEntity()
 if not IsValid(ent) then return end
 local rag=ent:GetNWEntity("RagdollEntityNO")
 if not IsValid(rag) and ent:GetClass()=="prop_ragdoll" then rag=ent end
 if not IsValid(rag) then return end
 local bone=rag:LookupBone("ValveBiped.Bip01_Head1")
 if bone==nil then return end
 local pos=rag:GetBonePosition(bone)
 if not isvector(pos) then pos=data:GetOrigin() end
 for i=1,math.random(5,8) do
  local fx=EffectData()
  fx:SetFlags(1);fx:SetMagnitude(bone);fx:SetOrigin(pos);fx:SetEntity(rag);fx:SetColor(BLOOD_COLOR_RED)
  util.Effect("br_blood_stream",fx)
  util.Effect("br_blood_spray",fx)
 end
end
function EFFECT:Think() return false end
function EFFECT:Render() end
