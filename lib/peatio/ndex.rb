require "active_support/core_ext/object/blank"
require "active_support/core_ext/enumerable"
require "peatio"

module Peatio
  module Ndex
    require "bigdecimal"
    require "bigdecimal/util"

    require "peatio/ndex/blockchain"
    require "peatio/ndex/client"
    require "peatio/ndex/wallet"

    require "peatio/ndex/hooks"

    require "peatio/ndex/version"
  end
end
