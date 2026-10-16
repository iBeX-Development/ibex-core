module.exports = {
  apps: [
    {
      name: "smartgps-front",
      script: "npx",
      args: "nuxi start .app",
      cwd: "/var/www/smartgps-front", // adjust if needed
      restart_delay: 500,

      env: {
        NODE_ENV: "production",
        PORT: 3002,
      },

      env_file: ".env.smartgps"
    }
  ]
}

