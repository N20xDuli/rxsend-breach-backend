-- Custom entrance audio must be available to clients without Workshop subscriptions.
for _,name in ipairs({"uiu","ci","scarlet"}) do
 resource.AddFile("sound/rxsend/factions/"..name.."_intro.ogg")
end
