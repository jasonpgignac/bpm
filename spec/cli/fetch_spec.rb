require "spec_helper"

describe 'bpm fetch' do
  
  before do
    goto_home
    FileUtils.cp_r(fixtures('hello_world'), '.')
    set_host
    start_fake(FakeGemServer.new)
  end

  it "fetches all dependencies in a project when called without command" do
    cd home('hello_world')
    bpm "fetch"

    stdout.read.should include("Fetched dependent packages for hello_world")

    # note: ivory is a soft dependency from core-test
    %w(spade-0.5.0 core-test-0.4.9 ivory-0.0.1 optparse-1.0.1).each do |package_name|
      package_name.should be_fetched
      package_name.should be_unpacked
    end
    
  end

  it "fetches a valid package" do
    bpm "fetch", "rake"

    stdout.read.should include("Successfully fetched rake (0.8.7)")

    "rake-0.8.7".should be_fetched
    "rake-0.8.7".should be_unpacked
  end

  it "fetches a multiple gems" do
    bpm "fetch", "rake", "builder"

    output = stdout.read

    %w(builder-3.0.0 rake-0.8.7).each do |pkg|
      output.should include("Successfully fetched #{pkg.sub(/-[^-]*$/,'')} (#{pkg.sub(/^.*-/, '')})")
      pkg.should be_fetched
      pkg.should be_unpacked
    end
  end

  it "fetches valid gems while ignoring invalid ones" do
    bpm "fetch", "rake", "fake", :track_stderr => true

    stdout.read.should include("Successfully fetched rake (0.8.7)")
    stderr.read.should include("Can't find package fake")

    "rake-0.8.7".should be_fetched
    "rake-0.8.7".should be_unpacked
    "fake-0".should_not be_fetched
    "fake-0".should_not be_unpacked
  end

  it "fails when fetching an invalid gem" do
    bpm "fetch", "fake", :track_stderr => true

    stderr.read.should include("Can't find package fake")
    "rake-0.8.7".should_not be_fetched
    "rake-0.8.7".should_not be_unpacked
    "fake-0".should_not be_fetched
    "fake-0".should_not be_unpacked
  end

  it "fails if bpm can't write to the bpm directory" do
    FileUtils.mkdir_p bpm_dir
    FileUtils.chmod 0555, bpm_dir

    bpm "fetch", "rake", :track_stderr => true
    exit_status.should_not be_success

    "rake-0.8.7".should_not be_fetched
    "rake-0.8.7".should_not be_unpacked
  end

  it "fetches gems with a different version" do
    bpm "fetch", "rake", "-v", "0.8.6"

    stdout.read.should include("Successfully fetched rake (0.8.6)")

    "rake-0.8.7".should_not be_fetched
    "rake-0.8.7".should_not be_unpacked
    "rake-0.8.6".should be_fetched
    "rake-0.8.6".should be_unpacked
  end

  it "fetches a valid prerelease package" do
    bpm "fetch", "bundler", "--pre"

    stdout.read.should include("Successfully fetched bundler (1.1.pre)")

    "bundler-1.1.pre".should be_fetched
    "bundler-1.1.pre".should be_unpacked
  end

  it "does not fetch the normal package when asking for a prerelease" do
    bpm "fetch", "rake", "--pre", :track_stderr => true

    stderr.read.should include("Can't find package rake")

    "rake-0.8.7".should_not be_fetched
    "rake-0.8.7".should_not be_unpacked
    "rake-0.8.6".should_not be_fetched
    "rake-0.8.6".should_not be_unpacked
  end

  it "requires at least one package to fetch (when not in a project)" do
    bpm "fetch", :track_stderr => true
    stderr.read.should include("called incorrectly")
  end

  it "does not make a .gem directory" do
    bpm "fetch", "rake"
    wait
    home(".gem").exist?.should be_false
  end

  it "fetches package dependencies" do
    bpm "fetch", "core-test"

    output = stdout.read

    %w(ivory-0.0.1 optparse-1.0.1 core-test-0.4.9).each do |name|
      output.should include("Successfully fetched #{name.sub(/-[^-]*$/,'')} (#{name.sub(/^.*-/, '')})")

      name.should be_fetched
      name.should be_unpacked
    end
  end
    
end
