// apollo.config.js
module.exports = {
  client: {
    service: {
      name: "Mobilizon",
      // URL to the GraphQL API
      localSchemaFile: "./schema.graphql",
    },
    // Files processed by the extension
    includes: ["src/**/*.vue", "src/**/*.js"],
  },
};
