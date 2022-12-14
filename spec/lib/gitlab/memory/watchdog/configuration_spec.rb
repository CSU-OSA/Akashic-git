# frozen_string_literal: true

require 'fast_spec_helper'
require_dependency 'gitlab/cluster/lifecycle_events'

RSpec.describe Gitlab::Memory::Watchdog::Configuration do
  subject(:configuration) { described_class.new }

  describe '#initialize' do
    it 'initialize monitors' do
      expect(configuration.monitors).to be_an_instance_of(described_class::MonitorStack)
    end
  end

  describe '#handler' do
    context 'when handler is not set' do
      it 'defaults to NullHandler' do
        expect(configuration.handler).to be(Gitlab::Memory::Watchdog::NullHandler.instance)
      end
    end
  end

  describe '#logger' do
    context 'when logger is not set, defaults to stdout logger' do
      it 'defaults to Logger' do
        expect(configuration.logger).to be_an_instance_of(::Gitlab::Logger)
      end
    end
  end

  describe '#sleep_time_seconds' do
    context 'when sleep_time_seconds is not set' do
      it 'defaults to SLEEP_TIME_SECONDS' do
        expect(configuration.sleep_time_seconds).to eq(described_class::DEFAULT_SLEEP_TIME_SECONDS)
      end
    end
  end

  describe '#monitors' do
    context 'when monitors are configured to be used' do
      let(:payload1) do
        {
          message: 'monitor_1_text',
          memwd_max_strikes: 5,
          memwd_cur_strikes: 0
        }
      end

      let(:payload2) do
        {
          message: 'monitor_2_text',
          memwd_max_strikes: 0,
          memwd_cur_strikes: 1
        }
      end

      let(:monitor_class_1) do
        Struct.new(:threshold_violated, :payload) do
          def call
            { threshold_violated: !!threshold_violated, payload: payload || {} }
          end

          def self.name
            'Monitor1'
          end
        end
      end

      let(:monitor_class_2) do
        Struct.new(:threshold_violated, :payload) do
          def call
            { threshold_violated: !!threshold_violated, payload: payload || {} }
          end

          def self.name
            'Monitor2'
          end
        end
      end

      context 'when two monitors are configured to be used' do
        before do
          configuration.monitors.use monitor_class_1, false, { message: 'monitor_1_text' }, max_strikes: 5
          configuration.monitors.use monitor_class_2, true, { message: 'monitor_2_text' }, max_strikes: 0
        end

        it 'calls each monitor and returns correct results', :aggregate_failures do
          payloads = []
          thresholds = []
          strikes = []
          monitor_names = []

          configuration.monitors.call_each do |result|
            payloads << result.payload
            thresholds << result.threshold_violated?
            strikes << result.strikes_exceeded?
            monitor_names << result.monitor_name
          end

          expect(payloads).to eq([payload1, payload2])
          expect(thresholds).to eq([false, true])
          expect(strikes).to eq([false, true])
          expect(monitor_names).to eq([:monitor1, :monitor2])
        end
      end

      context 'when same monitor class is configured to be used twice' do
        before do
          configuration.monitors.use monitor_class_1, max_strikes: 1
          configuration.monitors.use monitor_class_1, max_strikes: 1
        end

        it 'calls same monitor only once' do
          expect do |b|
            configuration.monitors.call_each(&b)
          end.to yield_control.once
        end
      end
    end
  end
end
