require 'unit_spec_helper'

describe Rapns::Daemon::AppRunner, 'stop' do
  let(:runner) { stub }
  before { Rapns::Daemon::AppRunner.runners['app'] = runner }
  after { Rapns::Daemon::AppRunner.runners.clear }

  it 'stops all runners' do
    runner.should_receive(:stop)
    Rapns::Daemon::AppRunner.stop
  end
end

describe Rapns::Daemon::AppRunner, 'deliver' do
  let(:runner) { stub }
  let(:notification) { stub(:app_id => 1) }
  let(:logger) { stub(:error => nil) }

  before do
    Rapns::Daemon.stub(:logger => logger)
    Rapns::Daemon::AppRunner.runners[1] = runner
  end

  after { Rapns::Daemon::AppRunner.runners.clear }

  it 'delivers the notification' do
    runner.should_receive(:deliver).with(notification)
    Rapns::Daemon::AppRunner.deliver(notification)
  end

  it 'logs an error if there is no runner to deliver the notification' do
    notification.stub(:app_id => 2, :id => 123)
    logger.should_receive(:error).with("No such app '#{notification.app_id}' for notification #{notification.id}.")
    Rapns::Daemon::AppRunner.deliver(notification)
  end
end

describe Rapns::Daemon::AppRunner, 'sync' do
  let(:app) { stub(:id => 1) }
  let(:new_app) { stub(:id => 2) }
  let(:runner) { stub(:sync => nil, :stop => nil, :start => nil) }
  let(:logger) { stub(:error => nil) }

  before do
    Rapns::Daemon::AppRunner.stub(:new_runner_for_app => runner)
    Rapns::Daemon::AppRunner.runners[app.id] = runner
    Rapns::App.stub(:all => [app])
  end

  after { Rapns::Daemon::AppRunner.runners.clear }

  it 'loads all apps' do
    Rapns::App.should_receive(:all)
    Rapns::Daemon::AppRunner.sync
  end

  it 'instructs existing runners to sync' do
    runner.should_receive(:sync).with(app)
    Rapns::Daemon::AppRunner.sync
  end

  it 'starts a runner for a new app' do
    Rapns::App.stub(:all => [app, new_app])
    new_runner = stub
    Rapns::Daemon::AppRunner.should_receive(:new_runner).and_return(new_runner)
    new_runner.should_receive(:start)
    Rapns::Daemon::AppRunner.sync
  end

  it 'deletes old apps' do
    Rapns::App.stub(:all => [])
    runner.should_receive(:stop)
    Rapns::Daemon::AppRunner.sync
  end
end
