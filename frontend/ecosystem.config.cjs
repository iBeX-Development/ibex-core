module.exports = {
    apps : [
        {
            name: "limble-front",
            script: "npx",
            args: "nuxi start .app --open",
            restart_delay: 500,
            env: {
              NODE_ENV: "production",
              PORT: 3001,
            }
        }
    ]
}
