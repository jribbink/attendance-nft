const createExpoWebpackConfigAsync = require("@expo/webpack-config");

module.exports = async function (env, argv) {
  const config = await createExpoWebpackConfigAsync(env, argv);
  // Customize the config before returning it.

  const cadenceRule = {
    test: /\.cdc$/i,
    loader: "raw-loader",
    options: {
      esModule: false,
    },
  };
  config.module.rules.find((r) => r.oneOf).oneOf.unshift(cadenceRule);

  return config;
};
