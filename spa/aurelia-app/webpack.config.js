const path = require('path');
const { AureliaPlugin } = require('aurelia-webpack-plugin');
const CopyWebpackPlugin = require('copy-webpack-plugin');

module.exports = {
  mode: 'production',
  entry: {
    app: './src/main.ts'
  },
  output: {
    path: path.resolve(__dirname, '../dist'),
    filename: 'axis-app.js',
    publicPath: ''
  },
  resolve: {
    extensions: ['.ts', '.js'],
    modules: [path.resolve(__dirname, 'src'), 'node_modules']
  },
  module: {
    rules: [
      { test: /\.ts$/, loader: 'ts-loader' },
      { test: /\.html$/, loader: 'html-loader' },
      { test: /\.css$/, loader: ['style-loader', 'css-loader'] }
    ]
  },
  plugins: [
    new AureliaPlugin(),
    new CopyWebpackPlugin({
      patterns: [
        { from: 'node_modules/bootstrap/dist/css/bootstrap.css', to: 'css/bootstrap.css' }
      ]
    })
  ]
};
