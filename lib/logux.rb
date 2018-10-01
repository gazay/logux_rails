# frozen_string_literal: true

require 'configurations'
require 'rest-client'
require 'rails/engine'
require 'active_support'
require 'hashie/mash'
require 'logux/engine'
require 'nanoid'
require 'colorize'

module Logux
  extend ActiveSupport::Autoload
  include Configurations

  class NoPolicyError < StandardError; end
  class NoActionError < StandardError; end

  autoload :Client, 'logux/client'
  autoload :Meta, 'logux/meta'
  autoload :Actions, 'logux/actions'
  autoload :Auth, 'logux/auth'
  autoload :BaseController, 'logux/base_controller'
  autoload :ActionController, 'logux/action_controller'
  autoload :ChannelController, 'logux/channel_controller'
  autoload :ClassFinder, 'logux/class_finder'
  autoload :ActionCaller, 'logux/action_caller'
  autoload :PolicyCaller, 'logux/policy_caller'
  autoload :Policy, 'logux/policy'
  autoload :Add, 'logux/add'
  autoload :Node, 'logux/node'
  autoload :Response, 'logux/response'
  autoload :Stream, 'logux/stream'
  autoload :Process, 'logux/process'
  autoload :Logger, 'logux/logger'
  autoload :Version, 'logux/version'
  autoload :Test, 'logux/test'

  configurable :logux_host, :verify_authorized,
               :password, :logger,
               :on_error, :auth_rule

  configuration_defaults do |config|
    config.logux_host = 'localhost:1338'
    config.verify_authorized = true
    config.logger = ActiveSupport::Logger.new(STDOUT)
    config.logger = Rails.logger if defined?(Rails) && Rails.respond_to?(:logger)
    config.on_error = proc {}
    config.auth_rule = proc { false }
  end

  def self.add(data, meta: {})
    logux_add = Logux::Add.new
    logux_meta = Logux::Meta.new(meta)
    logux_add.call(data, meta: logux_meta)
  end

  def self.add_batch(data, meta: {})
    raise 'Not working yet, can not share metadata between different actions'
    logux_add = Logux::AddBatch.new
    logux_meta = Logux::Meta.new(meta)
    logux_add.call(data, meta: logux_meta)
  end

  def self.verify_request_meta_data(meta_params)
    if Logux.configuration.password.nil?
      logger.warn(%(Please, add passoword for logux server:
                          Logux.configure do |c|
                            c.password = 'your-password'
                          end))
    end
    auth = Logux.configuration.password == meta_params&.dig(:password)
    raise unless auth
  end

  def self.process_batch(stream:, batch:)
    Logux::Process::Batch.new(stream: stream, batch: batch).call
  end

  def self.generate_action_id
    Logux::Node.instance.generate_action_id
  end

  def self.logger
    Logux::Logger
  end
end
