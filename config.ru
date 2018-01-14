require './lib/racker'

use Rack::Reloader
use Rack::Static, urls: ['/src'], root: 'lib'
run Racker
