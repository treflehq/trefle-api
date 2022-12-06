const path    = require("path")
const webpack = require("webpack")
// Extracts CSS into .css file
const MiniCssExtractPlugin = require('mini-css-extract-plugin');
// Removes exported JavaScript files from CSS-only entries
// in this example, entry.custom will create a corresponding empty custom.js file
const RemoveEmptyScriptsPlugin = require('webpack-remove-empty-scripts');
const mode = process.env.NODE_ENV === 'development' ? 'development' : 'production';

module.exports = {
  mode,
  optimization: {
    moduleIds: 'deterministic',
  },
  entry: {
    application: './app/assets/javascripts/application.js',
    codesandbox: './app/assets/javascripts/home/codesandbox.js',
    home: './app/assets/javascripts/home/home.js',
    manage: './app/assets/javascripts/manage.js',
    SpeciesPage: { import: './app/assets/javascripts/explore/SpeciesPage.jsx', filename: 'explore/[name].js' },
    DataPage: { import: './app/assets/javascripts/explore/DataPage.jsx', filename: 'explore/[name].js' },
  },
  output: {
    filename: "[name].js",
    sourceMapFilename: "[file].map",
    path: path.resolve(__dirname, '..', '..', 'app/assets/builds'),
  },
  resolve: {
    extensions: ['.js', '.jsx', '.scss', '.css'],
  },
  plugins: [
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    }),
    new RemoveEmptyScriptsPlugin(),
    new MiniCssExtractPlugin(),
  ],
  module: {
    rules: [
        {
          test: /\.(js|jsx|ts|tsx|)$/,
          exclude: /node_modules/,
          use: ['babel-loader'],
        },
        {
          test: /\.(?:sa|sc|c)ss$/i,
          use: [MiniCssExtractPlugin.loader, 'css-loader', 'sass-loader'],
        },
        {
          test: /\.(png|jpe?g|gif|eot|woff2|woff|ttf|svg)$/i,
          use: 'file-loader',
        },
    ],
  },

}
