<Game>
    <Service ClassName="ServerScriptService">
        <Script name="ServerMain">
            <LuaSource>require(game.ServerScriptService.ServerMain)</LuaSource>
        </Script>
    </Service>
    
    <Service ClassName="StarterPlayer">
        <PlayerScripts>
            <Script name="StarterGui">
                <LuaSource>require(game.StarterPlayer.StarterGui)</LuaSource>
            </Script>
            <Script name="UIController">
                <LuaSource>require(game.StarterPlayer.UIController)</LuaSource>
            </Script>
            <Script name="EmoteController">
                <LuaSource>require(game.StarterPlayer.EmoteController)</LuaSource>
            </Script>
            <Script name="CraftingGui">
                <LuaSource>require(game.StarterPlayer.CraftingGui)</LuaSource>
            </Script>
            <Script name="CombatGui">
                <LuaSource>require(game.StarterPlayer.CombatGui)</LuaSource>
            </Script>
            <Script name="InventoryGui">
                <LuaSource>require(game.StarterPlayer.InventoryGui)</LuaSource>
            </Script>
            <Script name="SpectatorMode">
                <LuaSource>require(game.StarterPlayer.SpectatorMode)</LuaSource>
            </Script>
            <Script name="ControllerSupport">
                <LuaSource>require(game.StarterPlayer.ControllerSupport)</LuaSource>
            </Script>
            <Script name="MobileSupport">
                <LuaSource>require(game.StarterPlayer.MobileSupport)</LuaSource>
            </Script>
        </PlayerScripts>
    </Service>
    
    <Service ClassName="ReplicatedFirst">
        <ModuleScript name="Config">
            <LuaSource>require(game.ReplicatedFirst.Config)</LuaSource>
        </ModuleScript>
        <ModuleScript name="CraftingRecipes">
            <LuaSource>require(game.ReplicatedFirst.CraftingRecipes)</LuaSource>
        </ModuleScript>
    </Service>
    
    <Service ClassName="ReplicatedStorage">
        <RemoteEvent name="LobbyRemoteEvent"/>
        <RemoteEvent name="EventsRemoteEvent"/>
        <RemoteEvent name="StatsRemoteEvent"/>
        <RemoteEvent name="ArenaRemoteEvent"/>
        <RemoteEvent name="InventoryRemoteEvent"/>
        <RemoteFunction name="CraftRemoteFunction"/>
        <RemoteEvent name="DamageRemoteEvent"/>
        <RemoteEvent name="WeaponRemoteEvent"/>
    </Service>
    
    <Service ClassName="Workspace">
        <Terrain/>
    </Service>
    
    <Service ClassName="Players">
        <Property name="CharacterAutoSpawn">true</Property>
        <Property name="MaximumPlayers">24</Property>
    </Service>
</Game>