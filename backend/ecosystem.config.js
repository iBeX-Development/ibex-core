module.exports = {
    apps : [
        {
            name: "smartgps-app",
            script: "npx",
            args: "directus start",
            restart_delay: 500,
	    env: {
        	PORT: 8057,
        	CONFIG_PATH: './smartgps/.env'
      	    }
        }
    ]
}
