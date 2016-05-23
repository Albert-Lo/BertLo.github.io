express = require 'express'
webpack = require 'webpack'
WebpackDevMiddleware = require 'webpack-dev-middleware'

app = express()

wpConfig = require './webpack.config'
compiler = webpack(wpConfig)

webpackDevMiddleware = WebpackDevMiddleware compiler,
  publicPath: wpConfig.output.publicPath

app.use webpackDevMiddleware

app.use express.static(__dirname)

app.get '/', (req, res, next) ->
  res.render 'index'

port = process.env.PORT || 8080

app.listen port, ->
  console.log "Development server listening on port #{port}"
