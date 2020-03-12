
module Peatio
  module Ndex
    # TODO: Processing of unconfirmed transactions from mempool isn't supported now.
    class Blockchain < Peatio::Blockchain::Abstract

      DEFAULT_FEATURES = {case_sensitive: true, cash_addr_format: false}.freeze

     def initialize(*)
      super
      @json_rpc_call_id  = 0
      @json_rpc_endpoint = URI.parse(blockchain.server)
    end

    def endpoint
      @json_rpc_endpoint
    end

    def latest_block_number
      Rails.cache.fetch "latest_#{self.class.name.underscore}_block_number", expires_in: 5.seconds do
        json_rpc({requestType: 'getBlocks', lastIndex: 0}).fetch('blocks')[0].fetch('height')
      end
    end

    def get_block(block_hash)
      json_rpc({requestType: 'getBlock', block: block_hash, includeTransactions: true})
    end

    def get_block_hash(height)
      current_block   = height || 0
      json_rpc({requestType: 'getBlockId', height: current_block}).fetch('block')
    end

    def get_unconfirmed_txns
      json_rpc({ requestType: 'getUnconfirmedTransactions'}).fetch('unconfirmedTransactions')
    end

    def get_raw_transaction(txid)
      json_rpc({ requestType: 'getTransaction', transaction: txid})
    end

    def build_transaction(tx, current_block, currency)
      { id:            normalize_txid(tx.fetch('transaction')),
        block_number:  current_block,
        entries: [
          {
            amount:  convert_from_base_unit(tx.fetch('amountNQT'), currency),
            address: normalize_address(tx['recipientRS'])
          }
        ]
      }
    end

    def to_address(tx)
      [normalize_address(tx.fetch('recipientRS'))]
    end

    def valid_transaction?(tx)
      [0, '0'].include?(tx['type'])
    end

    def invalid_transaction?(tx)
      !valid_transaction?(tx)
    end

  protected

    def connection
      Faraday.new(@json_rpc_endpoint).tap do |connection|
        unless @json_rpc_endpoint.user.blank?
          connection.basic_auth(@json_rpc_endpoint.user, @json_rpc_endpoint.password)
        end
      end
    end
    memoize :connection

    def json_rpc(params = {})
      response = connection.post do |req|
        req.url '/nxt?',
        req.body = params
      end
      response.assert_success!
      response = JSON.parse(response.body)
      response['errorDescription'].tap { |error| raise Error, error.inspect if error }
      response
    end
  end
end

