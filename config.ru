require './lib/racker'

use Rack::Static, urls: ['/src'], root: 'lib'
run Racker
