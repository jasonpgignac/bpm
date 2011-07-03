require "spec_helper"

describe BPM::Pipeline, "asset_path" do

  before do
    goto_home
    FileUtils.cp_r(fixtures('hello_world'), '.')
  end
  
  subject do
    project = BPM::Project.new home('hello_world')
    BPM::Pipeline.new project
  end
  
  it "should find any asset in the assets directory" do
    asset = subject.find_asset 'papa-smurf.jpg'
    asset.pathname.should == home('hello_world', 'assets', 'papa-smurf.jpg')
  end
  
  it "should find any asset in packages" do
    goto_home
    set_host
    start_fake(FakeGemServer.new)
    cd home('hello_world')
    
    bpm 'add', 'custom_package'
    wait
    
    asset = subject.find_asset 'custom_package/assets/dummy.txt'
    asset.pathname.should == home('hello_world', '.bpm', 'packages', 'custom_package', 'assets', 'dummy.txt')
  end
  
  it "should find any asset in installed packages" do
    goto_home
    set_host
    start_fake(FakeGemServer.new)
    cd home('hello_world')
    
    bpm 'compile'
    wait
  
    asset = subject.find_asset 'core-test/resources/runner.css'
    asset.pathname.should == home('hello_world', '.bpm', 'packages', 'core-test', 'resources', 'runner.css')
  end
  
  describe "generated assets" do

    before do
      goto_home
      set_host
      start_fake(FakeGemServer.new)
      cd home('hello_world')

      bpm 'add', 'custom_package'
      wait

      @project = BPM::Project.new home('hello_world')
    end

    describe "bpm_packages.js" do
  
      subject do
        BPM::Pipeline.new(@project).find_asset 'bpm_packages.js'
      end
    
      it "should return an asset of type BPM::GeneratedAsset" do
        subject.class.should == BPM::GeneratedAsset
      end
    
      it "should find the bpm_packages.js" do
        subject.pathname.should == home('hello_world', 'assets', 'bpm_packages.js')
      end
  
      it "should find bpm_packages as well" do
        BPM::Pipeline.new(@project).find_asset('bpm_packages').should == subject
      end
    
      it "should have a manifest line" do
        subject.to_s.should include('MANIFEST: core-test (0.4.9) custom_package (2.0.0) ivory (0.0.1) optparse (1.0.1) rake (0.8.6) spade (0.5.0)')
      end
    
      it "should include any required modules in the bpm_package.js" do
        subject.to_s.should include(File.read(home('hello_world', 'packages', 'custom_package', 'lib', 'main.js')))
      end
    
      it "should reference package.json directories when resolving modules" do
        subject.to_s.should include(File.read(home('hello_world', 'packages', 'custom_package', 'custom_dir', 'basic-module.js')))
      end
    
    end
  
    describe "bpm_styles.css" do
  
      subject do
        BPM::Pipeline.new(@project).find_asset 'bpm_styles.css'
      end
    
      it "should find bpm_styles.css" do
        subject.pathname.should == home('hello_world', 'assets', 'bpm_styles.css')
      end
    
      it "should include any required modules in the bpm_styles.css" do
        subject.to_s.should include(File.read(home('hello_world', 'packages', 'custom_package', 'css', 'sample_styles.css')))
      end
  
      it "should reference installed package styles as well" do
        subject.to_s.should include(File.read(home('hello_world', '.bpm', 'packages', 'core-test', 'resources', 'runner.css')))
      end
    
    end

    describe "hello_world/app_package.js" do
  
      before do
        FileUtils.mkdir_p home('hello_world', 'assets', 'hello_world')
        FileUtils.touch home('hello_world', 'assets', 'hello_world', 'app_package.js')
      end
    
      subject do
        BPM::Pipeline.new(@project).find_asset 'hello_world/app_package.js'
      end
    
      it "should return an asset of type BPM::GeneratedAsset" do
        subject.class.should == BPM::GeneratedAsset
      end
    
      it "should find the app_package.js" do
        subject.pathname.should == home('hello_world', 'assets', 'hello_world', 'app_package.js')
      end
  
      it "should find app_package as well" do
        BPM::Pipeline.new(@project).find_asset('hello_world/app_package').should == subject
      end
    
      it "should have a manifest line" do
        subject.to_s.should include('MANIFEST: hello_world (2.0.0)')
      end
    
      it "should include any required modules in the app_package" do
        subject.to_s.should include(File.read(home('hello_world', 'lib', 'main.js')))
      end
    end

    describe "hello_world/app_styles.css" do

      before do
        FileUtils.mkdir_p home('hello_world', 'assets', 'hello_world')
        FileUtils.touch home('hello_world', 'assets', 'hello_world', 'app_styles.css')
      end

      subject do
        BPM::Pipeline.new(@project).find_asset 'hello_world/app_styles.css'
      end

      it "should return an asset of type BPM::GeneratedAsset" do
        subject.class.should == BPM::GeneratedAsset
      end

      it "should find the app_styles.css" do
        subject.pathname.should == home('hello_world', 'assets', 'hello_world', 'app_styles.css')
      end

      it "should find app_styles as well" do
        BPM::Pipeline.new(@project).find_asset('hello_world/app_styles').should == subject
      end

      it "should have a manifest line" do
        subject.to_s.should include('MANIFEST: hello_world (2.0.0)')
      end

      it "should include any required modules in the app_package" do
        subject.to_s.should include(File.read(home('hello_world', 'css', 'dummy.css')))
      end

    end
      
  end
  
end


describe BPM::Pipeline, "buildable_assets" do

  before do
    set_host
    goto_home
    FileUtils.cp_r(fixtures('hello_world'), '.')
    reset_libgems bpm_dir.to_s

    start_fake(FakeGemServer.new)
    cd home('hello_world')

    bpm 'add', 'custom_package', '--verbose'
    wait

    @project = BPM::Project.new home('hello_world')
  end
  
  subject do
    BPM::Pipeline.new(@project).buildable_assets
  end
  
  def project(*asset_names)
    Pathname.new File.join @project.root_path, *asset_names
  end

  def find_asset(logical_path)
    subject.find { |x| x.logical_path == logical_path }
  end
  
  it "should include bpm_packages.js" do
    asset = find_asset 'bpm_packages.js'
    asset.should_not be_nil
    asset.pathname.should == project('assets', 'bpm_packages.js')
  end
  
  it "should include bpm_styles.css" do
    asset = find_asset 'bpm_styles.css'
    asset.should_not be_nil
    asset.pathname.should == project('assets', 'bpm_styles.css')
  end
  
  it "should include custom_package assets" do
    asset = find_asset 'custom_package/assets/dummy.txt'
    asset.should_not be_nil
    asset.pathname.should == project('.bpm', 'packages', 'custom_package', 'assets', 'dummy.txt')
  end
  
  it "should include installed package assets" do
    asset = find_asset 'core-test/resources/runner.css'
    asset.should_not be_nil
    asset.pathname.should == project('.bpm', 'packages', 'core-test', 'resources', 'runner.css')
  end
  
  it "should exclude libs" do
    asset = find_asset 'custom_package/assets/lib/main.js'
    asset.should be_nil
  end
  
end

describe BPM::Pipeline, 'transport processor' do

  before do
    goto_home
    set_host
    reset_libgems bpm_dir.to_s
    start_fake(FakeGemServer.new)
    
    FileUtils.cp_r fixtures('transporter'), '.'
    cd home('transporter')

    bpm 'compile'
    wait
  end
  
  subject do
    project = BPM::Project.new home('transporter')
    BPM::Pipeline.new project
  end
  
  it "should wrap the project's main.js" do
    asset = subject.find_asset 'transporter/lib/main.js'
    exp_path = home('transporter', 'lib', 'main.js')
    asset.to_s.should == "define_transport(function() {\n//TRANSPORT\ntransporter();\n//TRANSPORT\n\n}), 'transporter', 'main', '#{exp_path}');\n\n"
    asset.pathname.to_s.should == File.join(Dir.pwd, 'lib', 'main.js')
  end

  it "should not wrap transport/main.js" do
    asset = subject.find_asset 'transport/lib/main.js'
    asset.to_s.should == "// TRANSPORT DEMO\n"
  end

end

describe BPM::Pipeline, 'minifier' do

  before do
    goto_home
    set_host
    reset_libgems bpm_dir.to_s
    start_fake(FakeGemServer.new)
    
    FileUtils.cp_r fixtures('minitest'), '.'
    cd home('minitest')

    bpm 'compile'
    wait
  end
  
  subject do
    project = BPM::Project.new home('minitest')
    BPM::Pipeline.new project
  end
  
  it "should wrap bpm_packages.js" do
    asset = subject.find_asset 'bpm_packages.js'
    file_path = home('minitest', 'packages', 'uglyduck', 'lib', 'main.js')
    expected = <<EOF
//MINIFIED START
UGLY DUCK IS UGLY
/* ===========================================================================
   BPM Static Dependencies
   MANIFEST: uglyduck (1.0.0)
   This file is generated automatically by the bpm (http://www.bpmjs.org)    
   To use this file, load this file in your HTML head.
   =========================================================================*/

#{File.read file_path}
//MINIFIED END
EOF

    asset.to_s.should == expected
  end

  it "should wrap app_package.js" do
    asset = subject.find_asset 'minitest/app_package.js'
    file_path = home('minitest', 'lib', 'main.js')
    expected = <<EOF
//MINIFIED START
UGLY DUCK IS UGLY
/* ===========================================================================
   BPM Static Dependencies
   MANIFEST: minitest (2.0.0)
   This file is generated automatically by the bpm (http://www.bpmjs.org)    
   To use this file, load this file in your HTML head.
   =========================================================================*/

#{File.read(file_path)}
//MINIFIED END
EOF
    asset.to_s.should == expected
  end

end

  
