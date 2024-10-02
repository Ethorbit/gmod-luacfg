# gmod-luacfg
A flexible server config system parsed by Lua, an alternative to cfg.

## Why?

When you have people administrate your server, they probably don't understand lua that well, yet there might be times where they need to change lua.
Luacfg solves this problem by bridging the gap between lua and cfg, allowing devs to provide admins with a user-friendly way of changing lua.

While Source's cfg is not that different, it's bound by ugly Source limitations such as maximum # of commands.

## How it works

Devs define luacfg commands in their lua code, luacfg recursively parses files in cfg/luacfg/, Admins write to luacfg/

## Create a luacfg command

Developer, inside your lua:

```lua
hook.Add("luacfg.Initialized", "put_a_unique_value_here", function(args)
    luacfg.AddCommand("cat_lives", function(args)
        local lives = args[1]
        if !lives then return end
        file.Write("how-many-lives.txt", lives)
    end)
end)
```

Admin, inside cfg/luacfg/cat.luacfg (you can call it whatever):

```
cat_lives "9"
```

Restart.
You should now have a file _data/how-many-lives.txt_ that reads _9_. Luacfg!

<details>
<summary>Developer Hooks</summary>
<ul>
    <dl>
        <dt>luacfg.Initialized</dt>
        <dd>Ready for creation of commands</dd>
        <dt>luacfg.LoadFiles</dt>
        <dd>Files were read from a directory</dd>
        <dd>dir (string)</dd>
        <dt>luacfg.LoadFile</dt>
        <dd>A file was read</dd>
        <dd>file (string)</dd>
   </dl>
</ul>
</details>

<details>
<summary>Developer Methods</summary>
<ul>
    <dl>
      <dt>luacfg.AddCommand</dt>
      <dd>Adds a new luacfg command</dd>
      <dd>name (string)</dd>
      <dd>function (arguments [table])</dd>
      <dd>Returns nil</dd>
      <dt>luacfg.ParseCommand</dt>
      <dd>Parses a command from provided string</dd>
      <dd>command (string)</dd>
      <dd>Returns command (string), arguments (table)</dd>
      <dd>This is used internally..</dd>
      <dt>luacfg.LoadFile</dt>
      <dd>Loads file containing commands</dd>
      <dd>file path (string)</dd>
      <dd>Returns nil</dd>
      <dd>This is used internally..</dd>
      <dt>luacfg.LoadFiles</dt>
      <dd>Recursively loads all files in specified directory, or cfg/luacfg if not specified.</dd>
      <dd>dir (string)</dd>
      <dd>Returns nil</dd>
      <dd>This is used internally..</dd>
    </dl>
</ul>
</details>
